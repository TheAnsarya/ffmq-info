# FFMQ Function Reference

Complete reference for all documented functions in Final Fantasy: Mystic Quest.

**Last Updated:** 2025-11-05  
**Status:** Active - Continuously updated with code analysis  
**Coverage:** 2,090+ documented functions out of 8,153 total (~25.6%)

## Table of Contents

- [Overview](#overview)
- [Battle System Functions](#battle-system-functions)
  - [Damage Calculation](#damage-calculation)
  - [Enemy AI System](#enemy-ai-system)
- [Graphics System Functions](#graphics-system-functions)
  - [Tileset Loading and Management](#tileset-loading-and-management)
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

### Bank $01 - Battle System Core
- `Battle_Initialize` @ $8078 - Battle initialization
- `Battle_InitBuffers` @ $8168 - Initialize battle buffers
- `Battle_ClearVRAM` @ $820A - Clear VRAM for battle
- `Battle_LoadGraphics` @ $8244 - Load battle graphics
- `Battle_DecompressGraphics` @ $8286 - Decompress battle graphics
- `Battle_MainLoop` @ $838A - Main battle loop
- `Battle_ProcessTurn` @ $F326 - Process single combat turn
- `Battle_WaitVBlank` @ $8449 - VBlank synchronization

### Bank $02 - Battle System (AI & Combat)
- `Enemy_DecideAction` @ $C000 - Enemy AI decision-making
- `Enemy_SelectTarget` @ $C234 - Enemy target selection
- `Enemy_ExecuteAction` @ $C456 - Execute enemy action
- `CalculatePhysicalDamage` @ $C500 - Physical damage calculation
- `CalculateMagicDamage` @ $C600 - Magic damage calculation

### Bank $05 - Graphics/Palette
- `LoadPalette` @ $A000 - Load color palette into CGRAM

### Bank $06 - Map System
- `LoadMap` @ $A000 - Map loading
- `CheckCollision` @ $B234 - Collision detection

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

### Text & UI
- `PrintText` (Bank $08 @ $9000)
- `DecompressText` (Bank $08 @ $9234)

### Utilities
- `Random` (Bank $00 @ $8456)
- `Battle_WaitVBlank` (Bank $01 @ $8449)

---

## Contributing

This function reference is automatically updated as code is documented. To add or update function documentation:

1. Add proper function header comments in ASM files
2. Follow the documentation standard shown in [Overview](#overview)
3. Run `python tools/analyze_doc_coverage.py` to verify
4. Functions with complete headers will appear in this reference

See `docs/DOCUMENTATION_UPDATE_CHECKLIST.md` for complete guidelines.

---

**Note:** This is a living document. Not all functions are documented yet. Current coverage: **~25.6%** (2,090+ / 8,153 functions).

**Recent Additions (2025-11-05):**
- Added 10 battle system functions (initialization, main loop, turn processing)
- Added 3 enemy AI functions (decision-making, targeting, execution)
- Added 4 graphics system functions (tileset loading, decompression, palette, OAM)
- Expanded technical details with algorithms and data structures
- Added Quick Reference by Function Type

**Next Priority Areas:**
- Map system functions (collision, loading, NPCs)
- Item/inventory management functions
- Menu system functions
- Save/load system functions

For undocumented functions, see the source ASM files directly in `src/asm/`.
