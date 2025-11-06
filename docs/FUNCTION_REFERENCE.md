# FFMQ Function Reference

Complete reference for all documented functions in Final Fantasy: Mystic Quest.

**Last Updated:** 2025-11-05  
**Status:** Active - Continuously updated with code analysis  
**Coverage:** 2,125+ documented functions out of 8,153 total (~26.1%)

## Table of Contents

- [Overview](#overview)
- [Battle System Functions](#battle-system-functions)
  - [Damage Calculation](#damage-calculation)
  - [Enemy AI System](#enemy-ai-system)
- [Graphics System Functions](#graphics-system-functions)
  - [Tileset Loading and Management](#tileset-loading-and-management)
- [Text System Functions](#text-system-functions)
- [Map System Functions](#map-system-functions)
  - [Map Loading and Management](#map-loading-and-management)
  - [NPC Management](#npc-management)
- [Menu System Functions](#menu-system-functions)
  - [Battle Menu](#battle-menu)
  - [Equipment Menu](#equipment-menu)
- [Item & Inventory System Functions](#item--inventory-system-functions)
  - [Item Management](#item-management)
  - [Shop System](#shop-system)
- [Save/Load System Functions](#saveload-system-functions)
  - [Game State Persistence](#game-state-persistence)
- [Field Movement & Control Functions](#field-movement--control-functions)
  - [Player Control](#player-control)
  - [Menu Control](#menu-control)
- [Battle Item & Effect Functions](#battle-item--effect-functions)
  - [Item Usage in Battle](#item-usage-in-battle)
- [Sound System Functions](#sound-system-functions)
- [Utility Functions](#utility-functions)
- [Index by Bank](#index-by-bank)
- [Quick Reference by Function Type](#quick-reference-by-function-type)

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
- See `docs/BATTLE_SYSTEM.md` for battle mechanics overview

#### Battle_Initialize
**Location:** Bank $01 @ $8078  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Initialize battle system and set up initial battle state when entering combat.

**Inputs:**
- None (uses current game state from SRAM)

**Outputs:**
- Battle system fully initialized
- VRAM prepared for battle graphics
- Actor states reset

**Technical Details:**
- Clears battle RAM ($1900-$1FFF range)
- Initializes battle flags and counters
- Sets up actor states for all combatants
- Prepares graphics buffers
- Loads enemy data from ROM tables

**Side Effects:**
- Clears 256 bytes of battle RAM
- Modifies PPU registers for battle mode
- Sets up DMA channels for graphics
- Initializes `$19A5` (current enemy ID) to $FF
- Resets `$19AC` (turn counter) to 0
- Sets `$19D7` (battle mode) to 2
- Initializes `$19B4` (animation timer) to $40
- Initializes `$1993` (ATB gauge) to $10

**Calls:**
- `Battle_InitBuffers` - Initialize battle memory buffers
- `Battle_ClearVRAM` - Clear VRAM for battle graphics
- `Battle_LoadGraphics` - Load battle graphics into VRAM

**Called By:**
- Main game loop when transitioning to battle
- Random encounter trigger
- Scripted battle events

**Related:**
- See `docs/BATTLE_SYSTEM.md` for battle initialization sequence

#### Battle_InitBuffers
**Location:** Bank $01 @ $8168  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Initialize battle memory buffers and data structures.

**Inputs:**
- None

**Outputs:**
- Battle buffers cleared and ready
- Data structures initialized

**Technical Details:**
- Clears actor state buffers (HP, status, stats)
- Initializes combat queues
- Sets up sprite OAM buffers
- Prepares damage calculation scratch space

**Side Effects:**
- Modifies `$1900-$19FF` (actor data)
- Clears `$1A00-$1AFF` (battle state)
- Initializes `$1B00-$1BFF` (sprite buffers)

**Related:**
- Called by `Battle_Initialize`

#### Battle_ClearVRAM
**Location:** Bank $01 @ $820A  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Clear VRAM areas used by battle graphics.

**Inputs:**
- None

**Outputs:**
- VRAM cleared for battle

**Technical Details:**
- Clears character pattern tables
- Clears tilemap areas
- Resets sprite OAM
- Uses DMA for fast clearing

**Side Effects:**
- Modifies VRAM $0000-$7FFF
- Uses DMA channel 0
- Temporarily disables display during clear

**Algorithm:**
```
1. Disable screen (forced blank)
2. Set up DMA: source=$00, dest=VRAM, size=$8000
3. Trigger DMA transfer
4. Re-enable screen
```

**Related:**
- Called by `Battle_Initialize`

#### Battle_LoadGraphics
**Location:** Bank $01 @ $8244  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Load compressed battle graphics into VRAM.

**Inputs:**
- Current battle type determines which graphics to load

**Outputs:**
- Battle graphics loaded and decompressed in VRAM

**Technical Details:**
- Loads character sprites (party and enemies)
- Loads background tiles
- Loads UI elements
- Decompresses using custom RLE format

**Side Effects:**
- Uploads to VRAM $0000-$7FFF
- Calls `Battle_DecompressGraphics` multiple times
- Modifies `$00-$0F` (decompression scratch space)

**Calls:**
- `Battle_DecompressGraphics` - Decompress individual graphics

**Related:**
- See `docs/GRAPHICS_FORMATS.md` for compression format
- Called by `Battle_Initialize`

#### Battle_DecompressGraphics
**Location:** Bank $01 @ $8286  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Decompress RLE-compressed battle graphics.

**Inputs:**
- `$00-$01` = Source address (compressed data)
- `$02-$03` = Destination VRAM address

**Outputs:**
- Graphics decompressed to VRAM

**Technical Details:**
- Custom RLE compression format
- Control bytes indicate literal or repeat
- Handles 4bpp SNES tile format

**Compression Format:**
```
Control byte format:
  $00-$7F: Copy next N+1 bytes literally
  $80-$FF: Repeat next byte (N-127) times
```

**Side Effects:**
- Writes to VRAM via $2118-$2119
- Modifies `$00-$0F` (scratch space)

**Algorithm:**
```
while not end_of_data:
    control = read_byte()
    if control < $80:
        copy (control + 1) literal bytes
    else:
        repeat next byte (control - 127) times
```

**Related:**
- See `docs/GRAPHICS_FORMATS.md` for full compression spec
- Called by `Battle_LoadGraphics`

#### Battle_MainLoop
**Location:** Bank $01 @ $838A  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Main battle processing loop - runs every frame during combat.

**Inputs:**
- Current battle state from RAM

**Outputs:**
- Updated battle state
- Continues until battle ends

**Technical Details:**
- Processes input
- Updates actor states
- Handles turn order
- Processes animations
- Checks win/loss conditions
- Updates display

**Loop Structure:**
```
1. Wait for VBlank
2. Process controller input
3. Update Active Time Battle (ATB) gauges
4. Process pending actions
5. Update animations
6. Check battle end conditions
7. Repeat
```

**Side Effects:**
- Updates all battle RAM
- Modifies OAM for sprites
- Changes PPU state
- May trigger music/sound effects

**Calls:**
- `Battle_ProcessInput` - Handle controller
- `Battle_UpdateATB` - Update time gauges
- `Battle_ProcessActions` - Execute combat actions
- `Battle_UpdateAnimations` - Update sprite animations
- `Battle_CheckVictory` - Check win conditions

**Called By:**
- Main game loop during battle

**Related:**
- See `docs/BATTLE_SYSTEM.md` for battle flow diagram

#### Battle_ProcessTurn
**Location:** Bank $01 @ $F326  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Process a single combat turn for one actor.

**Inputs:**
- `A` = Actor index (0-3 = party, 4-11 = enemies)

**Outputs:**
- Turn executed
- Damage/effects applied

**Technical Details:**
- Determines action (attack, defend, item, magic, AI)
- Calculates target
- Applies damage/effects
- Updates actor states
- Triggers animations

**Turn Processing Flow:**
```
1. Check if actor can act (alive, not stunned)
2. Get action type (player choice or AI decision)
3. Select target(s)
4. Calculate effects (damage, status, etc.)
5. Apply effects to target(s)
6. Trigger animations/sounds
7. Update battle log/messages
8. Check for battle end
```

**Side Effects:**
- Modifies actor HP/MP/status
- Updates battle log
- Triggers sound effects
- May end battle

**Calls:**
- `Battle_GetAction` - Determine action
- `Battle_SelectTarget` - Choose target
- `CalculatePhysicalDamage` / `CalculateMagicDamage`
- `Battle_ApplyDamage` - Apply calculated damage
- `Battle_TriggerAnimation` - Start animations

**Called By:**
- `Battle_MainLoop` when actor's ATB gauge is full

**Related:**
- See `docs/BATTLE_SYSTEM.md` for turn flow
- See `docs/AI_SYSTEM.md` for enemy AI

### Enemy AI System

#### Enemy_DecideAction
**Location:** Bank $02 @ $C000  
**File:** `src/asm/bank_02_documented.asm`

**Purpose:** Enemy AI decision-making - chooses action based on enemy AI type and battle state.

**Inputs:**
- `A` = Enemy index (0-7)

**Outputs:**
- Action selected and queued
- Target determined

**Technical Details:**
- Reads enemy AI script from ROM
- Evaluates conditions (HP%, status, turn count)
- Selects action from available attacks
- Chooses target based on AI pattern

**AI Script Structure:**
```
Each enemy has AI table in ROM:
  Byte 0: AI pattern type
    $00 = Random attack
    $01 = Sequential pattern
    $02 = Conditional (HP-based)
    $03 = Counter-attack
    $04 = Support (heal/buff allies)
    
  Bytes 1+: Pattern-specific data
    For random: List of attack IDs with weights
    For sequential: Fixed attack sequence
    For conditional: HP thresholds and actions
```

**AI Pattern Types:**

**Random ($00):**
```
Weights-based selection:
  Attack1: 30% chance
  Attack2: 40% chance
  Attack3: 20% chance
  Defend:  10% chance
```

**Sequential ($01):**
```
Turn 1: Attack A
Turn 2: Attack B  
Turn 3: Attack C
Repeat from Turn 1
```

**Conditional ($02):**
```
If HP > 75%: Aggressive attacks
If HP 50-75%: Mixed attacks/defense
If HP 25-50%: Healing/support
If HP < 25%: Desperation attack
```

**Side Effects:**
- Updates enemy action queue
- Modifies `$1C00-$1CFF` (AI state)
- Calls `Random` for probabilistic choices
- May set enemy status flags

**Calls:**
- `Random` - For weighted random selection
- `Enemy_GetAttackList` - Get available attacks
- `Enemy_SelectTarget` - Choose target
- `Enemy_EvaluateConditions` - Check HP/status

**Called By:**
- `Battle_ProcessTurn` when processing enemy turn

**Related:**
- See `docs/AI_SYSTEM.md` for complete AI documentation
- See `docs/ENEMY_DATA.md` for AI script format

#### Enemy_SelectTarget
**Location:** Bank $02 @ $C234  
**File:** `src/asm/bank_02_documented.asm`

**Purpose:** Select target(s) for enemy action based on AI targeting rules.

**Inputs:**
- `A` = Enemy index
- `X` = Attack ID

**Outputs:**
- `Y` = Target index (or $FF for multi-target)
- Carry = Set if valid target found

**Technical Details:**
- Checks target type from attack data (single/multi, ally/enemy)
- For player targeting: Considers threat level, HP%, status
- For ally targeting: Prioritizes based on need (low HP for heal, etc.)
- Excludes dead/invalid targets

**Targeting Priorities:**

**For Attacks (target player):**
```
1. Highest threat (most damage dealt to enemy team)
2. Lowest HP% (finish off weak targets)
3. Front row (easier to hit)
4. Random if multiple equal priorities
```

**For Healing (target ally):**
```
1. Lowest HP% among allies
2. Priority to boss/stronger enemies
3. Skip if all allies at high HP
```

**For Buffs (target ally):**
```
1. Self if no allies
2. Strongest ally (highest attack/defense)
3. Ally without buff already active
```

**Side Effects:**
- Updates `$1D00` (target list)
- May modify threat values
- Calls `Random` for tie-breaking

**Algorithm:**
```
1. Get attack target type from attack data
2. Build list of valid targets
3. If single-target:
     Apply priority rules
     Select highest priority target
   If multi-target:
     Return $FF (all valid targets)
4. Return target index
```

**Called By:**
- `Enemy_DecideAction`
- Special enemy abilities

**Related:**
- See `docs/AI_SYSTEM.md` for targeting logic

#### Enemy_ExecuteAction
**Location:** Bank $02 @ $C456  
**File:** `src/asm/bank_02_documented.asm`

**Purpose:** Execute enemy attack/action after AI decision.

**Inputs:**
- `A` = Enemy index
- Enemy action queue contains selected action

**Outputs:**
- Action executed
- Damage/effects applied to target(s)

**Technical Details:**
- Retrieves action from queue
- Validates target still valid
- Calculates effects (damage, status, etc.)
- Applies effects
- Triggers animations and sounds
- Updates battle log

**Action Types:**
```
$00: Physical attack
$01: Magical attack  
$02: Special attack (unique effect)
$03: Heal ally
$04: Buff ally
$05: Debuff enemy
$06: Defend
$07: Flee (unused by most enemies)
```

**Side Effects:**
- Modifies target HP/MP/status
- Updates battle log messages
- Triggers sound effects
- Starts attack animations
- May proc counter-attacks or other reactions

**Calls:**
- `CalculatePhysicalDamage` or `CalculateMagicDamage`
- `ApplyDamage` - Apply calculated damage
- `ApplyStatusEffect` - Apply status changes
- `TriggerAnimation` - Start battle animation
- `UpdateBattleLog` - Show message

**Called By:**
- `Battle_ProcessTurn`

**Related:**
- See `docs/BATTLE_SYSTEM.md` for action execution flow

---

## Graphics System Functions

### Tileset Loading and Management

#### LoadTileset
**Location:** Bank $07 @ $8000  
**File:** `src/asm/bank_07_documented.asm`

**Purpose:** Load a tileset from ROM into VRAM for map/battle rendering.

**Inputs:**
- `A` = Tileset ID (0-63)

**Outputs:**
- Tileset loaded into VRAM
- Tileset metadata updated

**Technical Details:**
- Looks up tileset data in ROM table
- Determines if compression is used
- Loads to appropriate VRAM location ($0000-$3FFF typically)
- Updates tileset pointer in RAM

**Tileset ROM Structure:**
```
Offset  Size  Description
------  ----  -----------
$00     2     Pointer to graphics data
$02     2     Graphics data size
$04     1     Compression type (0=none, 1=RLE, 2=LZ77)
$05     1     Tile count
$06     2     VRAM destination address
```

**Side Effects:**
- Writes to VRAM $0000-$3FFF
- Updates `$7E2000` (current tileset ID)
- May call decompression routine
- Modifies `$00-$0F` (scratch space)

**Calls:**
- `DecompressGraphics` (if compressed)
- `DMA_Transfer` (for raw copy)

**Called By:**
- Map loading routine
- Battle initialization
- Mode 7 world map

**Related:**
- See `docs/GRAPHICS_FORMATS.md` for tileset format
- See `docs/DATA_STRUCTURES.md` for Tileset structure

#### DecompressGraphics
**Location:** Bank $07 @ $8234  
**File:** `src/asm/bank_07_documented.asm`

**Purpose:** Decompress graphics data using RLE or LZ77 compression.

**Inputs:**
- `$00-$01` = Source ROM address (compressed data)
- `$02-$03` = Destination VRAM/RAM address
- `$04` = Compression type (1=RLE, 2=LZ77)

**Outputs:**
- Decompressed graphics at destination

**Compression Formats:**

**RLE (Run-Length Encoding):**
```
Control byte:
  $00-$7F: Copy next (N+1) bytes literally
  $80-$FF: Repeat next byte (N-$7F) times
```

**LZ77 (Sliding Window):**
```
Control byte (bit flags for next 8 operations):
  0 = Copy 1 literal byte
  1 = Copy from sliding window
    Next 2 bytes: %LLLLLLLL %OOOODDDD
      L = Length (3-18 bytes)
      O+D = Offset in window (1-4096)
```

**Side Effects:**
- Writes to VRAM or WRAM depending on destination
- Modifies `$00-$0F` (decompression state)
- May take 1000+ cycles for large graphics

**Algorithm (RLE):**
```
while not end_marker:
    control = read_byte()
    if control < $80:
        # Literal run
        count = control + 1
        copy count bytes literally
    else:
        # Repeat run  
        count = control - $7F
        byte = read_byte()
        write byte count times
```

**Algorithm (LZ77):**
```
while not end_marker:
    flags = read_byte()
    for bit in flags (8 bits):
        if bit == 0:
            copy 1 literal byte
        else:
            length_offset = read_word()
            length = (length_offset >> 8) + 3
            offset = length_offset & $0FFF
            copy length bytes from offset in window
```

**Related:**
- See `docs/GRAPHICS_FORMATS.md` for compression specs
- Called by `LoadTileset`, `LoadSprite`, `Battle_LoadGraphics`

#### LoadPalette
**Location:** Bank $05 @ $A000  
**File:** `src/asm/bank_05_documented.asm`

**Purpose:** Load a 256-color palette (128 words) into CGRAM.

**Inputs:**
- `A` = Palette ID (0-15)
- `X` = Starting color index (0-255)
- `Y` = Number of colors to load (1-256)

**Outputs:**
- Palette loaded into CGRAM

**Technical Details:**
- Palette data stored in ROM at Bank $0D
- Colors in RGB555 format (2 bytes per color)
- Can load partial palettes for efficiency

**RGB555 Format:**
```
Bit:  15    10 9     5 4     0
      -BBBBB  GGGGG  RRRRR
      
Red   = bits 0-4   (0-31)
Green = bits 5-9   (0-31)  
Blue  = bits 10-14 (0-31)
Bit 15 = unused (always 0)
```

**Side Effects:**
- Writes to CGRAM via $2121-$2122
- Updates `$7E2010` (current palette ID)
- Modifies `$00-$03` (palette load state)

**Algorithm:**
```
1. Set CGRAM address ($2121) to starting color
2. For each color:
   - Write low byte to $2122
   - Write high byte to $2122
3. CGRAM address auto-increments
```

**Called By:**
- Map transitions
- Battle initialization
- Cutscene loading
- Time of day changes

**Related:**
- See `docs/DATA_STRUCTURES.md` for Palette structure
- See `docs/GRAPHICS_FORMATS.md` for color format

#### UpdateOAM
**Location:** Bank $00 @ $9234  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Update Object Attribute Memory (OAM) for sprite display.

**Inputs:**
- `$0400-$05FF` = OAM buffer (512 bytes)
- `$0600-$061F` = OAM high table (32 bytes)

**Outputs:**
- OAM updated in PPU

**Technical Details:**
- OAM holds 128 sprite entries (4 bytes each)
- High table holds X-position bit 9 and size flags
- DMA transfer during VBlank for speed

**OAM Entry Format (4 bytes):**
```
Byte 0: X position (low 8 bits)
Byte 1: Y position
Byte 2: Tile number
Byte 3: Attributes
  Bit 0-1: Palette (0-7)
  Bit 2-4: Priority (0-3)
  Bit 5:   Flip X
  Bit 6:   Flip Y
  Bit 7:   Tile page (0-1)
```

**High Table Format (1 byte per 4 sprites):**
```
Bit 0: Sprite 0 X bit 9
Bit 1: Sprite 0 size flag
Bit 2: Sprite 1 X bit 9
Bit 3: Sprite 1 size flag
... (pattern repeats)
```

**Side Effects:**
- DMA transfer to OAM during VBlank
- Uses DMA channel 0
- Modifies $2102-$2104 (OAM address/data)

**Algorithm:**
```
1. Wait for VBlank start
2. Set OAM address to $0000
3. DMA transfer $0400-$05FF to OAM (512 bytes)
4. Set OAM address to $0100  
5. DMA transfer $0600-$061F to OAM high (32 bytes)
```

**Called By:**
- NMI handler (every frame)
- Main game loop

**Related:**
- See `docs/GRAPHICS_SYSTEM.md` for OAM details

---

## Text System Functions

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

## Map System Functions

### Map Loading and Management

#### LoadMap
**Location:** Bank $06 @ $A000  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Load a map from ROM and initialize map state.

**Inputs:**
- `A` = Map ID (0-255)

**Outputs:**
- Map fully loaded and ready for rendering
- Player positioned at entry point

**Technical Details:**
- Loads map header from ROM
- Decompresses map data
- Loads tileset graphics
- Initializes NPCs and objects
- Sets up collision data
- Positions player at spawn point

**Map Header Structure (ROM):**
```
Offset  Size  Description
------  ----  -----------
$00     2     Map data pointer
$02     1     Tileset ID
$03     1     Palette ID
$04     1     Music track
$05     1     Map width (tiles)
$06     1     Map height (tiles)
$07     2     Collision data pointer
$09     2     NPC data pointer
$0B     2     Object data pointer
$0D     2     Event script pointer
$0F     1     Flags (weather, darkness, etc.)
```

**Side Effects:**
- Loads graphics into VRAM
- Updates map state in RAM ($7E2000-$7E3FFF)
- Initializes NPCs in RAM ($7E4000-$7E4FFF)
- Sets up collision map
- Changes background music
- Modifies player position

**Calls:**
- `LoadTileset` - Load map tileset
- `LoadPalette` - Load map palette
- `DecompressMapData` - Decompress map tiles
- `LoadCollisionData` - Load collision map
- `InitializeNPCs` - Set up NPCs
- `PlayMusic` - Start map music

**Called By:**
- Map transition routine
- Teleport/warp functions
- Game initialization

**Related:**
- See `docs/MAP_SYSTEM.md` for map format details
- See `docs/DATA_STRUCTURES.md` for MapHeader structure

#### CheckCollision
**Location:** Bank $06 @ $B234  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Check if a tile position is walkable or blocked.

**Inputs:**
- `X` = X tile coordinate (0-255)
- `Y` = Y tile coordinate (0-255)

**Outputs:**
- Carry flag: Set if blocked, clear if walkable
- `A` = Collision type byte

**Collision Types:**
```
$00 = Walkable
$01 = Blocked (wall/obstacle)
$02 = Water (requires float stone)
$03 = Lava (requires lava charm)
$04 = Spike floor (damages player)
$05 = Ice (slippery movement)
$06 = Stairs/ladder
$07 = Door/entrance
$08 = Warp tile
$09 = Battle trigger zone
$0A = Treasure chest
$0B = NPC blocking
$0C-$FF = Special collision handlers
```

**Technical Details:**
- Reads collision byte from collision map
- Checks player's items for special terrain (float stone, etc.)
- Handles special collision logic
- Updates movement flags

**Side Effects:**
- May modify movement direction flags
- May trigger random encounters (battle zones)
- May initiate map transitions (warps)

**Algorithm:**
```
1. Calculate collision map offset: (Y × map_width) + X
2. Read collision byte from map
3. Check for special items/abilities
4. Return collision result
```

**Called By:**
- Movement input handler
- NPC pathfinding
- Event placement validation

**Related:**
- See `docs/MAP_SYSTEM.md` for collision details

#### GetTileProperties
**Location:** Bank $06 @ $B456  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Get extended properties for a map tile.

**Inputs:**
- `X` = X tile coordinate
- `Y` = Y tile coordinate

**Outputs:**
- `A` = Tile properties byte
- `$00` = Tile ID
- `$01` = Collision type
- `$02` = Special flags

**Tile Properties Flags:**
```
Bit 0: Animated tile
Bit 1: Damage zone
Bit 2: Battle zone
Bit 3: Water tile
Bit 4: Require specific item
Bit 5: Hidden passage
Bit 6: Event trigger
Bit 7: Special script
```

**Side Effects:**
- None (read-only)

**Called By:**
- Rendering system (for animated tiles)
- Event system (for triggers)
- Movement system (for special handling)

**Related:**
- Called by `CheckCollision` for extended checks

### NPC Management

#### UpdateNPCs
**Location:** Bank $06 @ $C000  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Update all NPCs on current map (movement, animation, AI).

**Inputs:**
- None (uses NPC data in RAM)

**Outputs:**
- All NPCs updated

**Technical Details:**
- Updates up to 16 NPCs per map
- Processes NPC movement patterns
- Updates sprite animations
- Checks for player interaction
- Handles NPC AI scripts

**NPC Movement Patterns:**
```
$00 = Stationary (faces player when approached)
$01 = Random walk (4 directions)
$02 = Horizontal patrol (left-right)
$03 = Vertical patrol (up-down)
$04 = Circle pattern
$05 = Follow path (scripted waypoints)
$06 = Chase player (hostile)
$07 = Flee from player
$08 = Custom script
```

**Side Effects:**
- Updates NPC positions in RAM
- Updates NPC sprite OAM
- May trigger dialogue if player interacts
- Modifies `$7E4000-$7E4FFF` (NPC state)

**Algorithm:**
```
for each active NPC (max 16):
    1. Update animation frame
    2. Process movement pattern
    3. Check collision with map
    4. Update sprite position
    5. Check for player interaction
    6. Execute AI script if any
```

**Calls:**
- `CheckCollision` - Validate NPC movement
- `UpdateNPCAnimation` - Update sprite frame
- `CheckPlayerProximity` - Detect interaction

**Called By:**
- Main game loop (field mode)

**Related:**
- See `docs/NPC_SYSTEM.md` for NPC data structure

#### CheckPlayerProximity
**Location:** Bank $06 @ $C234  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Check if player is near an NPC for interaction.

**Inputs:**
- `A` = NPC index (0-15)

**Outputs:**
- Carry flag: Set if player is adjacent
- `X` = Distance X (signed)
- `Y` = Distance Y (signed)

**Technical Details:**
- Calculates Manhattan distance
- Checks if player is within 1 tile (adjacent)
- Accounts for NPC facing direction

**Interaction Distance:**
```
Adjacent tiles (distance = 1):
  [N]     North
[W][P][E] West-Player-East
  [S]     South
```

**Side Effects:**
- None (read-only check)

**Algorithm:**
```
1. Get player position (tile coordinates)
2. Get NPC position (tile coordinates)
3. Calculate dx = player.x - npc.x
4. Calculate dy = player.y - npc.y
5. If abs(dx) + abs(dy) == 1: Set carry
```

**Called By:**
- `UpdateNPCs` - Check for interactions
- Event system - Trigger dialogue
- Quest system - Check objectives

**Related:**
- Used for dialogue triggers

---

## Menu System Functions

### Battle Menu

#### DisplayBattleMenu
**Location:** Bank $03 @ $8000  
**File:** `src/asm/bank_03_documented.asm`

**Purpose:** Display and handle battle command menu.

**Inputs:**
- `A` = Character index (0-3)

**Outputs:**
- Selected command in action queue
- Menu closed

**Battle Commands:**
```
0: Attack  - Physical attack
1: Defend  - Reduce damage taken
2: Magic   - Spell menu
3: Item    - Item menu
4: Run     - Attempt to flee
```

**Technical Details:**
- Displays command window
- Highlights available commands
- Processes input
- Validates command availability (magic requires MP, etc.)
- Updates cursor position

**Side Effects:**
- Updates menu graphics in VRAM
- Modifies OAM for cursor sprite
- Updates battle state flags
- Sets selected command in RAM

**Calls:**
- `RenderMenuWindow` - Draw menu background
- `PrintMenuText` - Display command names
- `HandleMenuInput` - Process controller
- `ValidateCommand` - Check if command available

**Called By:**
- `Battle_ProcessTurn` when player turn starts

**Related:**
- See `docs/MENU_SYSTEM.md` for menu structure

#### HandleMenuInput
**Location:** Bank $03 @ $8234  
**File:** `src/asm/bank_03_documented.asm`

**Purpose:** Process controller input for menu navigation.

**Inputs:**
- `$00` = Current menu state
- Controller input from hardware

**Outputs:**
- `A` = Selected menu option (or $FF if cancelled)
- Carry flag: Set if selection confirmed

**Technical Details:**
- Reads controller port
- Handles D-pad navigation
- Processes A button (confirm) and B button (cancel)
- Updates cursor position
- Plays sound effects
- Handles menu wrapping

**Controller Mapping:**
```
D-Pad Up:    Move cursor up
D-Pad Down:  Move cursor down
D-Pad Left:  Move cursor left (if multi-column)
D-Pad Right: Move cursor right (if multi-column)
A Button:    Confirm selection
B Button:    Cancel/back
Start:       Pause menu (field mode only)
```

**Side Effects:**
- Updates cursor sprite position
- Plays menu sound effects
- Modifies `$01` (cursor position)

**Algorithm:**
```
1. Read controller input ($4218-$4219)
2. Check for new button presses (debounce)
3. If D-pad pressed:
     Update cursor position
     Wrap if at boundary
     Play cursor sound
4. If A button pressed:
     Validate selection
     Play confirm sound
     Return selection
5. If B button pressed:
     Play cancel sound
     Return $FF
```

**Called By:**
- All menu functions (battle, equipment, items, etc.)

**Related:**
- See `docs/INPUT_SYSTEM.md` for controller details

### Equipment Menu

#### DisplayEquipmentMenu
**Location:** Bank $03 @ $9000  
**File:** `src/asm/bank_03_documented.asm`

**Purpose:** Display character equipment screen with stat comparisons.

**Inputs:**
- `A` = Character index (0-3)

**Outputs:**
- Equipment changes saved
- Stats updated

**Technical Details:**
- Displays current equipment
- Shows available equipment in inventory
- Calculates stat changes when changing equipment
- Highlights stat improvements (green) and decreases (red)
- Handles equipment restrictions (character-specific)

**Equipment Slots:**
```
0: Weapon   - Affects Attack
1: Armor    - Affects Defense
2: Helmet   - Affects Defense/Magic Defense
3: Shield   - Affects Defense/Evasion
4: Accessory - Special effects
```

**Stat Display:**
```
Current → New
Attack:  50 → 65 (+15)  [Green if increase]
Defense: 30 → 28 (-2)   [Red if decrease]
Magic:   20 → 20 (---)  [White if no change]
```

**Side Effects:**
- Updates character equipment in SRAM
- Recalculates character stats
- Updates menu graphics
- Modifies inventory flags

**Calls:**
- `GetCharacterStats` - Current stats
- `CalculateEquipmentStats` - Projected stats
- `RenderStatComparison` - Show stat changes
- `SaveEquipmentChange` - Apply changes

**Called By:**
- Main menu system
- Shop equipment purchase
- Treasure chest equipment

**Related:**
- See `docs/EQUIPMENT_SYSTEM.md` for equipment data

---

## Item & Inventory System Functions

### Item Management

#### Item_AddItem
**Location:** Bank $00 @ $DB3B  
**File:** `src/asm/banks/bank_00.asm`

**Purpose:** Add an item to the player's inventory. Handles all item types (key items, consumables, weapons, etc.).

**Inputs:**
- `A` = Item ID (0-255)

**Outputs:**
- Item added to appropriate storage
- Inventory display updated

**Technical Details:**
- Item IDs are categorized by range
- Different handling for each item type
- Automatically manages inventory space
- Updates display counters
- Sets flags for new items

**Item ID Ranges:**
```
$00-$0F: Key Items (stored as bitflags in $0EA6+)
  - Mask, Crest, etc.
  - Uses bitfield storage (1 bit per item)
  
$10-$13: Party Member HP Items (Kaeli, etc.)
  - Special items that increase max HP
  - Stored at $1030, $10B0
  - Max value: 99 (0x63)
  
$14-$1F: Magic Items (stored as bitflags in $1038+)
  - Spell books, magic abilities
  - Bitfield storage
  
$20-$2E: Consumable Items (Cure, Heal, Refresh, etc.)
  - Stored at $1031-$1034
  - Bitfield + counter system
  - Special handling for Elixir ($26)
  
$2F-$DC: Weapons and Equipment
  - Stored as bitflags in $1035+
  - Used with equipment menu
  
$DD: Kaeli HP increase (special case)
$DE+: Other special items
```

**Side Effects:**
- Updates inventory bitfields
- Updates item count displays
- Sets `$00D4` bit 4 (inventory changed flag)
- May trigger menu refresh
- Plays item acquisition sound

**Algorithm:**
```
1. Compare item ID to ranges:
   If $00-$0F → Add key item (bitfield)
   If $10-$13 → Add party member HP item
   If $14-$1F → Add magic item (bitfield)
   If $20-$2E → Add consumable item
   If $2F-$DC → Add weapon/equipment (bitfield)
   If $DD → Special Kaeli HP
   Else → Other special items

2. For bitfield items:
   - Calculate bit position
   - Set appropriate bit in storage
   - Update display

3. For counted items:
   - Increment counter
   - Check max (usually 99)
   - Update count display
   - Set changed flag

4. Special cases (Elixir):
   - Clear bit $02 of $10B2
   - Set bit $04 of $10B3
   - Store $2D to $10B1
   - Update display at Y=$50
```

**Calls:**
- `Bitfield_SetBits` @ Bank $00 - Set bitfield flags
- `Menu_DisplayItemCount` @ $9111 - Update item count display

**Called By:**
- Treasure chest system
- Shop purchase
- NPC item gifts
- Battle reward system

**Related:**
- See `Item_RemoveItem` for removing items
- See `docs/ITEM_SYSTEM.md` for complete item data

---

#### Item_RemoveItem
**Location:** Bank $00 @ $DBF8  
**File:** `src/asm/banks/bank_00.asm`

**Purpose:** Remove an item from the player's inventory.

**Inputs:**
- `A` = Item ID to remove

**Outputs:**
- `A` = $FF if item was removed successfully
- Item removed from inventory

**Technical Details:**
- Primarily for consumable items
- Decrements item count
- Updates character stats for consumables

**Side Effects:**
- Decrements item counter at `$0E9F,X`
- Updates inventory display
- May trigger menu refresh

**Algorithm:**
```
1. Get character stats for item
2. Check if count > 0
3. If yes:
     Decrement count at $0E9F,X
     Return $FF (success)
   Else:
     Return with no change
```

**Calls:**
- `Item_GetCharacterStats` @ Bank $00 - Get item stats

**Called By:**
- Item use in battle
- Item use in field
- Shop sell system
- Equipment changes

---

#### Item_CanUseItem
**Location:** Bank $00 @ $DC3A  
**File:** `src/asm/banks/bank_00.asm`

**Purpose:** Check if an item can be used in current context.

**Inputs:**
- `A` = Item ID

**Outputs:**
- Carry flag: Set if item can be used, clear if not
- `A` = Item type/category

**Technical Details:**
- Checks item type
- Validates context (battle vs field)
- Checks requirements

**Validation Rules:**
```
Battle Context:
- Consumables: Always usable
- Weapons/Equipment: Not usable
- Key Items: Situation-specific

Field Context:
- Consumables: Usable on party
- Key Items: Situation-specific
- Weapons/Equipment: Only via equipment menu
```

**Called By:**
- Battle item command
- Field item menu
- Shop system

---

### Shop System

#### Shop_SubtractGold
**Location:** Bank $00 @ (inferred from documented code)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Subtract gold from player's current amount during shop transactions.

**Inputs:**
- Gold amount to subtract (from transaction)
- Current character gold amount

**Outputs:**
- Updated gold amount

**Technical Details:**
- Handles two different gold storage locations
- Validates sufficient funds
- Updates display

**Storage Locations:**
```
Primary:   Character-specific gold storage
Alternate: Secondary storage (special cases)
```

**Side Effects:**
- Updates gold amount in memory
- Updates shop display
- May trigger "not enough gold" message

**Called By:**
- Shop buy item
- Inn payment
- Other transaction systems

**Related:**
- Shop dialogue system in Bank $03
- Price calculation functions

---

## Save/Load System Functions

### Game State Persistence

#### Load_GameFromSRAM
**Location:** Bank $00 @ $713 (hex offset in bank)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Restore saved game data from SRAM (battery-backed save RAM).

**Inputs:**
- SRAM contains valid save data

**Outputs:**
- All game state restored to WRAM
- Save slot selected

**Technical Details:**
- Uses SNES SRAM mapping
- Supports multiple save slots (0, 1, 2)
- Block memory transfer via MVN instruction
- Validates save slot number

**SRAM Memory Map:**
```
Bank $70-$77 ($700000-$77FFFF):
  Battery-backed save RAM
  
Key SRAM Locations:
  $700000: Save slot 0 marker
  $70038C: Save slot 1 marker  
  $700718: Save slot 2 marker
  
Each slot stores:
  - Character stats and levels
  - Inventory and equipment
  - Progress flags and story state
  - Map position and party data
  - Play time and other metadata
```

**Process:**
```
1. Set 16-bit mode (REP #$30)

2. Copy Save Data Block 1:
   Source:      $0C:A9C2 (ROM data)
   Destination: $00:1010 (WRAM)
   Size:        $40 bytes (64 bytes)
   Method:      MVN $00,$0C

3. Copy Save Data Block 2:
   Source:      $0C:0E9E (ROM data)
   Destination: $00:1050 (WRAM)
   Size:        $0A bytes (10 bytes)
   Method:      MVN $00,$0C

4. Set save slot marker:
   $0FE7 = $02 (active save indicator)

5. Determine active save slot:
   Read $7E3668 (save slot number: 0, 1, or 2)
   If >= 2, reset to 0
   Increment and store back to $7E3668

6. Load slot-specific data from table

7. Restore character positions, inventory, flags

8. Initialize display with saved state
```

**MVN Instruction Details:**
```asm
MVN (Block Move Negative):
  Format: MVN srcbank,dstbank
  
  X = source address (16-bit)
  Y = destination address (16-bit)
  A = length - 1 (16-bit)
  
  Auto-increments X and Y
  Auto-decrements A
  Continues until A = $FFFF
  
  Example:
    LDX #$A9C2        ; Source = $0CA9C2
    LDY #$1010        ; Dest   = $001010
    LDA #$003F        ; Length = $40 bytes
    MVN $00,$0C       ; Copy from bank $0C to $00
```

**Side Effects:**
- Overwrites WRAM with save data
- Updates `$0FE7` (save slot marker)
- Updates `$7E3668` (active slot number)
- Modifies registers (A, X, Y)

**Called By:**
- Title screen "Continue" option
- Boot sequence if continue flag set

**Related:**
- See `Init_NewGameState` for new game initialization
- See save data validation routines

---

#### Init_NewGameState
**Location:** Bank $00 @ $627 (hex offset in bank)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Initialize all game state for a new game.

**Inputs:**
- None (new game start)

**Outputs:**
- Fresh game state in WRAM
- Default character stats
- Starting inventory
- Initial map position

**Technical Details:**
- Sets all default values
- Clears progress flags
- Initializes party members
- Sets starting location

**Default Values:**
```
Characters:
  - Starting level: 1
  - Starting HP: Character-specific defaults
  - Starting equipment: Basic gear
  - Magic: None initially

Inventory:
  - Empty consumable slots
  - No key items
  - No weapons/equipment collected

Progress:
  - All story flags cleared
  - No dungeons completed
  - Starting town position

Map:
  - Starting location: Hill of Destiny
  - Party: Benjamin only
  - Time: 0:00:00
```

**Process:**
```
1. Clear all WRAM game state ($1000-$1FFF)

2. Set default character stats:
   - Benjamin: Level 1, base stats
   - Other party slots: Empty

3. Initialize inventory:
   - Clear all item bitfields
   - Set consumable counts to 0
   - Clear equipment flags

4. Set starting position:
   - Map ID: Starting location
   - X/Y coordinates: Spawn point
   - Facing direction: Down

5. Initialize flags:
   - Clear all progress flags
   - Set "new game" marker
   - Reset event counters

6. Set starting equipment:
   - Benjamin: Steel Sword, Leather Armor
   - Other slots: Empty

7. Initialize timers:
   - Play time: 0
   - Step counter: 0
```

**Side Effects:**
- Clears WRAM game state area
- Sets all default values
- Initializes display state

**Called By:**
- Boot sequence when no save data exists
- "New Game" selection from title

**Related:**
- See `Load_GameFromSRAM` for loading saved games

---

#### ValidateSaveData
**Location:** Boot sequence  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Check if valid save data exists in SRAM before loading.

**Inputs:**
- SRAM contents

**Outputs:**
- Zero flag: Set if no valid save data, clear if save exists

**Technical Details:**
- Checks three SRAM marker bytes
- Uses OR operation to detect any non-zero values
- Fast validation without full checksum

**Validation Logic:**
```asm
lda.l $700000   ; A = SRAM slot 0 marker
ora.l $70038C   ; OR with slot 1 marker
ora.l $700718   ; OR with slot 2 marker
beq NoSaveData  ; If all zero → No save exists

; If non-zero → At least one save slot has data
```

**Marker Bytes:**
- If all three bytes are $00: No save data
- If any byte is non-zero: Save data exists
- Does NOT validate save data integrity (no checksum here)
- Full validation done during load

**Called By:**
- Boot sequence
- Title screen initialization

**Related:**
- Used before `Load_GameFromSRAM`
- Determines "Continue" option availability

---

## Field Movement & Control Functions

### Player Control

#### Field_UpdatePlayer
**Location:** Bank $01 @ $8E07  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Main player character update loop - processes movement, animation, collision, and NPC interactions.

**Inputs:**
- `$19A5` = Player movement lock flag
- `$19AC` = Player animation frame counter
- `$19DF` = NPC interaction target
- `$19E1` = NPC animation target

**Outputs:**
- Player position updated
- Collision detection processed
- NPCs updated
- Animation advanced

**Technical Details:**
- Core field mode update function
- Runs every frame during field exploration
- Coordinates all field subsystems
- Handles player and NPC state synchronization

**Process Flow:**
```
1. Check movement lock ($19A5)
   - If locked → Skip to collision check
   - If unlocked → Continue normal update

2. Process movement animation:
   - Increment animation counter ($19AC)
   - AND with $03 to wrap (0-3 frames)
   - Update NPC positions

3. Handle NPC direction:
   - Check if NPC direction needs update ($19DF)
   - If $FF → Skip NPC direction
   - Else → Update NPC facing direction
   - DMA transfer: 1 or 3 bytes depending on state

4. Handle NPC movement:
   - Update NPC positions via Field_NPCMovement
   - DMA transfer coordination ($420B)

5. Handle NPC animation:
   - Check if NPC animation active ($19E1)
   - If $FF → Skip NPC animation
   - Else → Advance NPC animation frames
   - DMA transfer: 1 or 3 bytes

6. Update sprite counters (Bank $7F):
   - Increment $CED8-$CEF2 (14 sprite counters)
   - Used for sprite animation timing

7. Update display:
   - Process color math based on map state ($19CB)
   - Update $2130-$2131 (color math registers)
   - Handle special lighting effects
```

**Subsystems Called:**
- `Field_ProcessNPC` @ $8F0E - Process NPC logic
- `Field_NPCDirection` @ $8F50 - Update NPC facing
- `Field_NPCMovement` @ $8F2E - Update NPC positions
- `Field_NPCAnimate` @ $8F6F - Advance NPC animations

**Side Effects:**
- Modifies `$19AC` (animation counter)
- Updates `$420B` (DMA register)
- Modifies Bank $7F sprite counters ($CED8-$CEF2)
- Updates `$2130-$2131` (PPU color math)
- Updates `$1A50-$1A51` (color math settings)

**Special Cases:**
- Movement lock ($19A5 != 0): Skips to collision check
- NPC interaction ($19DF != $FF): Updates NPC direction
- NPC animation ($19E1 != $FF): Advances NPC frames
- Map lighting ($19CB bit 4-6): Special color math

**Called By:**
- Main field loop
- Every frame during exploration

**Related:**
- See `Field_ProcessInput` for controller input
- See `Field_EntityCollision` for collision system

---

#### Field_ProcessInput
**Location:** Bank $01 @ $E9B3  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Process player controller input during field mode.

**Inputs:**
- Controller input from `$4218-$4219`
- Current player state
- Movement flags

**Outputs:**
- Player movement state updated
- Direction changed if D-pad pressed
- Actions triggered (talk, open menu, etc.)

**Technical Details:**
- Reads SNES controller ports
- Handles all D-pad directions
- Processes action buttons
- Manages menu triggering

**Controller Mapping:**
```
D-Pad:
  Up:    Move player north
  Down:  Move player south
  Left:  Move player west
  Right: Move player east

Action Buttons:
  A Button:      Talk to NPC / Check object / Open chest
  B Button:      Use equipped item (axe, bomb, etc.)
  X Button:      Open main menu
  Y Button:      (Context-specific)
  L/R Buttons:   Switch party leader (if applicable)
  Start:         Open menu (same as X)
  Select:        Open map (if available)
```

**Movement Processing:**
```
1. Read controller state ($4218-$4219)
2. Check for new button presses (debounce)
3. Priority order:
   - Action buttons (A, B, X, Y)
   - D-Pad movement
   - Menu buttons (Start, Select)

4. For D-Pad input:
   - Determine direction (0-3: Down, Left, Up, Right)
   - Check if movement allowed (not blocked)
   - Update player facing direction
   - Set movement state
   - Start walk animation

5. For A button:
   - Check for NPC in front
   - Check for interactive object
   - Trigger appropriate action

6. For menu buttons:
   - Save current state
   - Enter menu mode
   - Disable field movement
```

**Debouncing:**
- Tracks previous frame input
- Only triggers on new presses (rising edge)
- Prevents accidental multiple activations

**Side Effects:**
- Updates player direction
- Sets movement flags
- May trigger NPC dialogue
- May open menus
- May use field items

**Called By:**
- Main field loop
- Every frame when not in dialogue/menu

**Related:**
- See `Field_UpdatePlayer` for movement execution
- See `Field_EntityCollision` for collision

---

### Menu Control

#### Menu_ProcessInput
**Location:** Bank $01 @ $C6C0  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Process controller input for menu navigation and scrolling.

**Inputs:**
- `Y` = Number of scroll steps to process
- `$19C1-$19C3` = Scroll state backup
- `$19F1` = Current entity index
- Controller input

**Outputs:**
- Menu scrolled
- Cursor position updated
- World map rendered (if applicable)
- Entity collision updated

**Technical Details:**
- Handles menu scrolling with sub-pixel precision
- Updates multiple coordinate systems
- Coordinates with world map rendering
- Processes collision during menu scroll

**Process Flow:**
```
1. Save current state:
   - Backup $19C1 → $19BD
   - Backup $19C3 → $19BF
   - Backup $19F1 → $192D

2. For each scroll step (loop Y times):
   a. Update vertical position:
      - Add offset from DATA8_01C714 (indexed by X)
      - Update $192E (Y coordinate)
   
   b. Update horizontal scroll:
      - Subtract $08 from $192D
      - Update scroll register
   
   c. Update tile alignment:
      - Add $05 to $19BF
      - Add offset from table
      - AND with $0F (wrap to 16)
      - Update $19BF
   
   d. Render world map:
      - Call Field_RenderWorldMap
      - Update visible tiles
   
   e. Process collision:
      - Store entity index to $0E89
      - Set collision mode ($1A46 = $02)
      - Call Field_EntityCollision
   
   f. Loop control:
      - Decrement Y
      - Continue if Y >= 0

3. Restore state:
   - Restore entity index from $19F1
   - Store to $0E89
   - Pop stack (X, bank, status)
```

**Scroll Data Table (DATA8_01C714):**
```
Offset values for smooth scrolling:
$05, $FB, $04, $FC, $03, $FD, $02, $FE, $01, $FF, $00
(Positive and negative offsets for sub-pixel movement)
```

**Side Effects:**
- Modifies `$19BD, $19BF, $192D, $192E` (scroll coordinates)
- Updates `$0E89` (entity index)
- Sets `$1A46` (collision mode)
- Triggers world map redraw
- Updates collision state

**Called By:**
- Menu scroll routines
- World map navigation
- Menu transitions

**Related:**
- See `Field_RenderWorldMap` for rendering
- See `Field_EntityCollision` for collision

---

## Battle Item & Effect Functions

### Item Usage in Battle

#### Battle_UseItem
**Location:** Bank $02 @ $926D  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Execute item usage during battle - validates item, applies effects, and handles special cases.

**Inputs:**
- `$90` = Using character index
- `$8F` = Target character index
- `$38` = Item ID being used
- Current battle state

**Outputs:**
- Item effect applied to target
- Battle state updated
- Item consumed (if consumable)

**Technical Details:**
- Validates item can be used in battle
- Handles different item types (cure, heal, refresh, etc.)
- Manages status effect removal
- Triggers appropriate animations

**Item Effect Types:**
```
Cure Items:
  - Cure Potion: Restores HP
  - Heal Potion: Restores more HP
  - X-Cure: Fully restores HP

Status Cure Items:
  - Refresh: Cures poison
  - Unicorn: Cures paralysis
  - Eye Drops: Cures blind
  - Remedy: Cures all status effects

Special Items:
  - Elixir: Restores all HP and status
  - Phoenix Down: Revives KO'd ally
  - Ether: Restores spell uses
```

**Process Flow:**
```
1. Compare user and target ($90 vs $8F):
   - If same → Cure mute status first
   - Apply Battle_CureMute

2. Validate item usage:
   - Check if target valid
   - Verify item in inventory
   - Confirm item usable in battle

3. Set entity context:
   - Call Battle_SetEntityContextEnemy
   - Prepare target data

4. Calculate effect amount:
   - For HP restore: Base value + variance
   - For status cure: Clear appropriate flags
   - For special items: Multi-effect processing

5. Check target status:
   - Call Battle_CheckTargetDeath
   - Skip if target KO'd (unless Phoenix Down)

6. Initialize animation:
   - Call Battle_InitializeAnimation
   - Show item use effect
   - Display healing numbers

7. Apply actual effect:
   - Update target HP/status
   - Remove item from inventory
   - Update battle display
```

**Status Effect Handling:**
```
Paralysis ($3A == $11):
  - Call Battle_CureParalysis
  - Set $E2 = $24 (effect type)
  - Set $DF = $15 (animation)

Mute (User == Target):
  - Call Battle_CureMute
  - Calculate hit chance

Other Status Effects:
  - Check $11 bit 3 (status debuff flag)
  - Call Battle_ApplyStatDebuff
  - Validate effect application
```

**Special Cases:**
```
Elixir Usage:
  - Restores all HP to max
  - Cures all status effects
  - Special animation sequence
  - Consumed after use

Phoenix Down:
  - Only usable on KO'd allies
  - Restores to partial HP
  - Clears KO status
  - Special resurrection animation

Stat Debuff Items:
  - Apply negative effects to enemies
  - Check resistance
  - Calculate success rate
```

**Side Effects:**
- Updates target HP at battle entity offset
- Clears status flags ($11, $21)
- Consumes item from inventory
- Sets animation flags ($E2, $DF, $B7)
- Modifies battle state registers
- Updates $77 (effect amount)

**Calls:**
- `Battle_CureMute` @ $97BE - Remove mute status
- `Battle_CureParalysis` @ $97B8 - Remove paralysis
- `Battle_CalculateHitChance` @ $A0E1 - Calculate success
- `Battle_SetEntityContextEnemy` @ $8F2F - Set target context
- `Battle_CheckTargetDeath` @ $95DE - Verify target alive
- `Battle_InitializeAnimation` @ $9C9B - Start effect animation
- `Battle_ApplyStatDebuff` @ $9964 - Apply status effect

**Called By:**
- Battle command processor
- Item menu selection handler

**Related:**
- See `Item_RemoveItem` for inventory management
- See `docs/BATTLE_MECHANICS.md` for item data
- See battle animation system for visual effects

---

#### Battle_ApplyItemEffect
**Location:** Bank $02 @ $931D  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Apply the actual effect of a battle item after validation.

**Inputs:**
- `$90` = Using character
- `$8F` = Target character
- Validated item and target

**Outputs:**
- Item effect applied
- Battle status updated
- Animation triggered

**Technical Details:**
- Called after Battle_UseItem validation
- Handles final effect application
- Manages status flag updates

**Process:**
```
1. Check user vs target:
   - If same character → Cure mute
   - Else → Skip mute cure

2. Calculate hit chance:
   - Call Battle_CalculateHitChance
   - Determine if effect succeeds

3. Set entity context:
   - Call Battle_SetEntityContextEnemy
   - Target data loaded to direct page

4. Update status flags:
   - Clear temporary status ($21)
   - Keep only bit 7 (permanent status)
   - $21 = $21 AND $80

5. Restore context:
   - Pop direct page
   - Return to battle loop
```

**Status Flag Management:**
```
$21 (Target Status Flags):
  Bit 7: Permanent status (preserved)
  Bits 0-6: Temporary status (cleared by items)
  
After item effect:
  $21 = ($21 AND $80)
  Only permanent status remains
```

**Side Effects:**
- Modifies `$21` (target status)
- Updates direct page context
- May cure mute status

**Calls:**
- `Battle_CureMute` @ $97BE - Conditional mute cure
- `Battle_CalculateHitChance` @ $A0E1 - Success calculation
- `Battle_SetEntityContextEnemy` @ $8F2F - Context setup

**Called By:**
- `Battle_UseItem` - After validation

**Related:**
- Works with `Battle_UseItem` for complete item system

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
- `UpdateOAM` @ $9234 - Update sprite OAM
- `Item_AddItem` @ $DB3B - Add item to inventory
- `Item_RemoveItem` @ $DBF8 - Remove item from inventory
- `Item_CanUseItem` @ $DC3A - Check if item can be used
- `Item_GetCharacterStats` - Get character stats for item
- `Shop_SubtractGold` - Subtract gold for purchases
- `Load_GameFromSRAM` @ $713 - Load saved game from SRAM
- `Init_NewGameState` @ $627 - Initialize new game state
- `ValidateSaveData` - Check for valid save data
- `Bitfield_SetBits` @ $974E - Set bits in bitfield

### Bank $01 - Battle System Core
- `Battle_Initialize` @ $8078 - Battle initialization
- `Battle_InitBuffers` @ $8168 - Initialize battle buffers
- `Battle_ClearVRAM` @ $820A - Clear VRAM for battle
- `Battle_LoadGraphics` @ $8244 - Load battle graphics
- `Battle_DecompressGraphics` @ $8286 - Decompress battle graphics
- `Battle_MainLoop` @ $838A - Main battle loop
- `Battle_ProcessTurn` @ $F326 - Process single combat turn
- `Battle_WaitVBlank` @ $8449 - VBlank synchronization
- `Field_UpdatePlayer` @ $8E07 - Player movement and update
- `Field_ProcessInput` @ $E9B3 - Controller input processing
- `Menu_ProcessInput` @ $C6C0 - Menu navigation and scrolling
- `Field_ProcessNPC` @ $8F0E - NPC logic processing
- `Field_NPCDirection` @ $8F50 - NPC facing update
- `Field_NPCMovement` @ $8F2E - NPC position update
- `Field_NPCAnimate` @ $8F6F - NPC animation advance

### Bank $02 - Battle System (AI & Combat)
- `Enemy_DecideAction` @ $C000 - Enemy AI decision-making
- `Enemy_SelectTarget` @ $C234 - Enemy target selection
- `Enemy_ExecuteAction` @ $C456 - Execute enemy action
- `CalculatePhysicalDamage` @ $C500 - Physical damage calculation
- `CalculateMagicDamage` @ $C600 - Magic damage calculation
- `Battle_UseItem` @ $926D - Use item in battle
- `Battle_ApplyItemEffect` @ $931D - Apply item effect
- `Battle_CureMute` @ $97BE - Remove mute status
- `Battle_CureParalysis` @ $97B8 - Remove paralysis status
- `Battle_CalculateHitChance` @ $A0E1 - Success rate calculation
- `Battle_SetEntityContextEnemy` @ $8F2F - Set target context
- `Battle_CheckTargetDeath` @ $95DE - Verify target alive
- `Battle_InitializeAnimation` @ $9C9B - Start effect animation
- `Battle_ApplyStatDebuff` @ $9964 - Apply status effect

### Bank $03 - Menu System
- `DisplayBattleMenu` @ $8000 - Battle command menu
- `HandleMenuInput` @ $8234 - Menu input processing
- `DisplayEquipmentMenu` @ $9000 - Equipment screen
- `GetCharacterStats` - Character stat calculation
- `CalculateEquipmentStats` - Equipment stat preview
- `SaveEquipmentChange` - Apply equipment changes

### Bank $05 - Graphics/Palette
- `LoadPalette` @ $A000 - Load color palette into CGRAM

### Bank $06 - Map System
- `LoadMap` @ $A000 - Map loading and initialization
- `CheckCollision` @ $B234 - Collision detection
- `GetTileProperties` @ $B456 - Tile property lookup
- `UpdateNPCs` @ $C000 - NPC update loop
- `CheckPlayerProximity` @ $C234 - Player-NPC distance check
- `DecompressMapData` - Map data decompression
- `LoadCollisionData` - Collision map loading
- `InitializeNPCs` - NPC initialization

### Bank $07 - Graphics System
- `LoadTileset` @ $8000 - Load tileset into VRAM
- `DecompressGraphics` @ $8234 - Decompress graphics (RLE/LZ77)

### Bank $08 - Text Engine
- `PrintText` @ $9000 - Text rendering
- `DecompressText` @ $9234 - Text decompression (DTE)

### Bank $0B - Battle Graphics
- See `src/asm/bank_0B_documented.asm` for battle-specific graphics

### Bank $0C - Mode 7/World Map
- See `src/asm/bank_0C_documented.asm` for Mode 7 functions

### Bank $0D - Sound/APU
- `PlayMusic` @ $8000 - Music playback (SPC700)

---

## Quick Reference by Function Type

### Initialization
- `InitializeSystem` (Bank $00 @ $8000)
- `Battle_Initialize` (Bank $01 @ $8078)
- `Battle_InitBuffers` (Bank $01 @ $8168)

### Battle Processing
- `Battle_MainLoop` (Bank $01 @ $838A)
- `Battle_ProcessTurn` (Bank $01 @ $F326)
- `Enemy_DecideAction` (Bank $02 @ $C000)
- `Enemy_ExecuteAction` (Bank $02 @ $C456)

### Damage Calculation
- `CalculatePhysicalDamage` (Bank $02 @ $C500)
- `CalculateMagicDamage` (Bank $02 @ $C600)

### Graphics
- `LoadTileset` (Bank $07 @ $8000)
- `LoadPalette` (Bank $05 @ $A000)
- `DecompressGraphics` (Bank $07 @ $8234)
- `Battle_LoadGraphics` (Bank $01 @ $8244)
- `UpdateOAM` (Bank $00 @ $9234)

### Map & World
- `LoadMap` (Bank $06 @ $A000)
- `CheckCollision` (Bank $06 @ $B234)
- `GetTileProperties` (Bank $06 @ $B456)
- `UpdateNPCs` (Bank $06 @ $C000)
- `CheckPlayerProximity` (Bank $06 @ $C234)

### Menu & UI
- `DisplayBattleMenu` (Bank $03 @ $8000)
- `HandleMenuInput` (Bank $03 @ $8234)
- `DisplayEquipmentMenu` (Bank $03 @ $9000)
- `Menu_ProcessInput` (Bank $01 @ $C6C0)

### Field Movement & Control
- `Field_UpdatePlayer` (Bank $01 @ $8E07)
- `Field_ProcessInput` (Bank $01 @ $E9B3)
- `Field_ProcessNPC` (Bank $01 @ $8F0E)
- `Field_NPCDirection` (Bank $01 @ $8F50)
- `Field_NPCMovement` (Bank $01 @ $8F2E)
- `Field_NPCAnimate` (Bank $01 @ $8F6F)

### Battle Items & Effects
- `Battle_UseItem` (Bank $02 @ $926D)
- `Battle_ApplyItemEffect` (Bank $02 @ $931D)
- `Battle_CureMute` (Bank $02 @ $97BE)
- `Battle_CureParalysis` (Bank $02 @ $97B8)
- `Battle_CalculateHitChance` (Bank $02 @ $A0E1)
- `Battle_CheckTargetDeath` (Bank $02 @ $95DE)
- `Battle_InitializeAnimation` (Bank $02 @ $9C9B)
- `Battle_ApplyStatDebuff` (Bank $02 @ $9964)

### Item & Inventory
- `Item_AddItem` (Bank $00 @ $DB3B)
- `Item_RemoveItem` (Bank $00 @ $DBF8)
- `Item_CanUseItem` (Bank $00 @ $DC3A)
- `Shop_SubtractGold` (Bank $00)

### Save/Load
- `Load_GameFromSRAM` (Bank $00 @ $713)
- `Init_NewGameState` (Bank $00 @ $627)
- `ValidateSaveData` (Bank $00)

### Text & UI
- `PrintText` (Bank $08 @ $9000)
- `DecompressText` (Bank $08 @ $9234)

### Utilities
- `Random` (Bank $00 @ $8456)
- `Battle_WaitVBlank` (Bank $01 @ $8449)
- `Bitfield_SetBits` (Bank $00 @ $974E)

---

## Contributing

This function reference is automatically updated as code is documented. To add or update function documentation:

1. Add proper function header comments in ASM files
2. Follow the documentation standard shown in [Overview](#overview)
3. Run `python tools/analyze_doc_coverage.py` to verify
4. Functions with complete headers will appear in this reference

See `docs/DOCUMENTATION_UPDATE_CHECKLIST.md` for complete guidelines.

---

**Note:** This is a living document. Not all functions are documented yet. Current coverage: **~26.1%** (2,125+ / 8,153 functions).

**Recent Additions (2025-11-05):**
- Added 10 battle system functions (initialization, main loop, turn processing)
- Added 3 enemy AI functions (decision-making, targeting, execution)
- Added 4 graphics system functions (tileset loading, decompression, palette, OAM)
- Added 5 map system functions (loading, collision, tiles, NPCs, proximity)
- Added 3 menu system functions (battle menu, input handling, equipment)
- Added 4 item/inventory functions (add, remove, check usage, shop gold)
- Added 3 save/load functions (load from SRAM, new game init, validation)
- Added 3 field movement functions (player update, input processing, menu control)
- Added 2 battle item functions (item usage, effect application)
- Expanded technical details with algorithms and data structures
- Added Quick Reference by Function Type

**Next Priority Areas:**
- Status effect processing system
- More field collision functions
- Shop buy/sell interfaces
- Advanced battle effects**Next Priority Areas:**
- Item effects and status processing
- Save/load SRAM structure details
- Field movement and player control
- Shop system (buy/sell interfaces)
- Battle item effects

**Next Priority Areas:**
- Item/inventory management functions
- Save/load system functions  
- Field movement and player control
- Shop system functions
- Status effect processing

For undocumented functions, see the source ASM files directly in `src/asm/`.
