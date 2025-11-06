# FFMQ Function Reference

Complete reference for all documented functions in Final Fantasy: Mystic Quest.

**Last Updated:** 2025-11-05  
**Status:** Active - Continuously updated with code analysis  
**Coverage:** 2,179+ documented functions out of 8,153 total (~26.7%)

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
  - [Camera System](#camera-system)
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
  - [Collision Detection](#collision-detection)
- [Battle Item & Effect Functions](#battle-item--effect-functions)
  - [Item Usage in Battle](#item-usage-in-battle)
  - [Status Effect Processing](#status-effect-processing)
- [Sprite & Graphics Functions](#sprite--graphics-functions)
  - [OAM Management](#oam-management)
  - [Sprite Animation](#sprite-animation)
- [Battle Damage Modifiers](#battle-damage-modifiers)
  - [Elemental System](#elemental-system)
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

### Palette Loading

#### Palette_Load8Colors
**Location:** Bank $00 @ ~$A14B  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Fast 8-color palette load to CGRAM using unrolled loop.

**Inputs:**
- `A` (8-bit) = CGRAM starting address (0-255)
- `X` (16-bit) = Source offset in DATA8_078000
- Data Bank = $07, Direct Page = $2100

**Outputs:**
- 8 colors (16 bytes) loaded into CGRAM

**Technical Details:**
- Unrolled 16-byte write (~144 cycles)
- RGB555 format (2 bytes per color)
- Auto-increment CGRAM address
- Used for text palettes, UI elements

**Process:**
```asm
STA $2121          ; Set CGRAM address
LDA DATA8_078000,X ; Color byte 0
STA $2122          ; Write to CGRAM
... (repeat for 16 bytes total)
RTS
```

**Use Cases:**
- Text rendering (dialogue colors)
- UI elements (cursor, menus)
- Small sprite palettes (≤8 colors)

**Performance:** ~18 cycles per color, ~3% of VBLANK budget

**Called By:** Graphics_InitFieldMenu (4× for menu setup)

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

### Camera System

#### Field_CameraScroll
**Location:** Bank $01 @ $8B76  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Disable camera scrolling by clearing scroll enable flags.

**Inputs:**
- None

**Outputs:**
- `$008E` = Modified (bits 4-5 cleared)
- Camera scrolling disabled

**Technical Details:**
- Uses TRB (Test and Reset Bits) instruction
- Clears bits 4-5 of camera control flags
- Atomic operation (PHP/PLP for safety)
- Preserves all other processor state

**Process Flow:**
```asm
1. PHP                    ; Save processor status
2. SEP #$20              ; 8-bit A mode
3. REP #$30              ; 16-bit index mode
4. LDA #$4030            ; Bits 4-5 mask
5. TRB $008E             ; Test and Reset Bits
   - Tests if bits are set
   - Clears bits 4-5
   - Sets Z flag if bits were clear
6. PLP                   ; Restore status
7. RTS
```

**Camera Control Flags ($008E):**
```
Bit 0-3: Camera mode
  $00: Free camera
  $01: Follow player
  $02: Cutscene mode
  $03: Fixed position

Bit 4: X-axis scroll enable
  0: X scrolling disabled
  1: X scrolling enabled

Bit 5: Y-axis scroll enable
  0: Y scrolling disabled
  1: Y scrolling enabled

Bit 6-7: Reserved
```

**TRB Operation:**
```
TRB (Test and Reset Bits):
  Before: $008E = %01110101 (bits 4-5 set)
  Mask:   #$4030 = %01000000 00110000
  After:  $008E = %00100101 (bits 4-5 cleared)
  Z flag: Clear (bits were set)
```

**Use Cases:**
- Entering dialogue (lock camera)
- Menu transitions (prevent scroll)
- Cutscene start (fixed position)
- Battle transitions (freeze field)

**Side Effects:**
- Modifies `$008E` (camera flags)
- May affect scroll behavior immediately
- Preserves all registers

**Called By:**
- Dialogue system initialization
- Menu open routines
- Cutscene triggers
- Battle transition

**Related:**
- See `Field_CameraUpdate` for enabling scroll
- See `Field_CameraCalculate` for scroll calculations
- See `Field_UpdateCamera` for camera positioning

---

#### Field_CameraUpdate
**Location:** Bank $01 @ $8B83  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Enable camera scrolling by setting scroll enable flags.

**Inputs:**
- None

**Outputs:**
- `$008E` = Modified (bits 4-5 set)
- Camera scrolling enabled

**Technical Details:**
- Uses TSB (Test and Set Bits) instruction
- Sets bits 4-5 of camera control flags
- Counterpart to `Field_CameraScroll` (disable)
- Atomic operation with state preservation

**Process Flow:**
```asm
1. PHP                    ; Save processor status
2. SEP #$20              ; 8-bit A mode
3. REP #$30              ; 16-bit index mode
4. LDA #$4030            ; Bits 4-5 mask
5. TSB $008E             ; Test and Set Bits
   - Tests if bits are set
   - Sets bits 4-5
   - Sets Z flag if bits were clear
6. PLP                   ; Restore status
7. RTS
```

**TSB Operation:**
```
TSB (Test and Set Bits):
  Before: $008E = %00100101 (bits 4-5 clear)
  Mask:   #$4030 = %01000000 00110000
  After:  $008E = %01110101 (bits 4-5 set)
  Z flag: Set (bits were clear)
```

**Bit Mask ($4030):**
```
Binary: 0100 0000 0011 0000
Bit 4: X-axis scroll (hex $0010)
Bit 5: Y-axis scroll (hex $0020)
Combined: $4030

OR operation for both axes
```

**Camera Re-enable Sequence:**
```
Typical usage:
  1. Field_CameraScroll (disable)
  2. [Dialogue/menu/cutscene]
  3. Field_CameraUpdate (enable)
  4. Field_CameraCalculate (resume)
```

**Use Cases:**
- Exiting dialogue (unlock camera)
- Menu close (resume scroll)
- Cutscene end (restore control)
- Battle return to field

**Side Effects:**
- Modifies `$008E` (camera flags)
- Camera may snap/jump if position changed
- Preserves all registers

**Calls:**
- None (simple flag set)

**Called By:**
- Dialogue close routines
- Menu close handlers
- Cutscene end triggers
- Battle exit

**Related:**
- See `Field_CameraScroll` for disabling scroll
- See `Field_CameraCalculate` for position calculation
- See camera control documentation

---

#### Field_CameraCalculate
**Location:** Bank $01 @ $8B90  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Calculate camera position based on player position with screen edge clamping.

**Inputs:**
- `$1914` = Player X position (pixel coordinates)
- `$1917` = Map scroll flags
- `$19E8` = Entity index
- `$1A7F,X` = Entity flags
- `$19B5` = Base address

**Outputs:**
- `$192B` = Calculated camera X offset (0-31 tiles)
- `$0A9C` = Final clamped position

**Technical Details:**
- Converts pixel positions to tile coordinates
- Handles screen edge cases (prevent off-screen)
- Uses bitfield checking for special cases
- Clamps camera to valid scroll range

**Process Flow:**
```
1. Initialize registers:
   SEP #$20              ; 8-bit A
   REP #$10              ; 16-bit index
   LDA #$00
   XBA                   ; Clear high byte

2. Extract tile position:
   LDA $1914             ; Player X position
   AND #$1F              ; Mask to 0-31 tiles
   STA $192B             ; Store tile coordinate

3. Check scroll threshold:
   CMP #$14              ; Compare with 20
   BCC CameraClampX      ; If < 20, clamp directly

4. Check map scroll flags:
   LDA $1917             ; Load scroll flags
   ROL × 3               ; Rotate bits 0-2 to positions 3-5
   AND #$03              ; Mask to 0-3
   INC A                 ; Add 1 for bitfield index

5. Call bitfield check:
   JSL $009776           ; Check if scroll allowed
   BEQ CameraClamp       ; If bit clear, use base position

6. Add scroll offset:
   LDA $192B
   CLC
   ADC #$08              ; Add 8-tile offset
   → CameraClampCheck

7. Store result:
   STA $0A9C             ; Final clamped position
   RTS
```

**Scroll Regions:**
```
Player X position determines camera behavior:
  
  Tiles 0-19 ($00-$13):
    Direct mapping (no offset)
    Camera = Player tile position
  
  Tiles 20-31 ($14-$1F):
    Scroll threshold reached
    Check map scroll flags
    If allowed: Camera = Position + 8
    If blocked: Camera = Base position
```

**Map Scroll Flags ($1917):**
```
Bits 0-2: Scroll permissions
  Rotated 3 times → bits 3-5
  AND #$03 → extract 2 bits
  INC → bitfield index (1-4)

Bitfield lookup @ $009776:
  Returns: 0 = scroll blocked
           1 = scroll allowed
```

**Entity Edge Check:**
```
If scroll check fails:
  LDX $19E8             ; Entity index
  LDA $1A7F,X           ; Entity flags
  BIT #$20              ; Check bit 5 (edge flag)
  BEQ CameraClamp       ; If clear, use base
  
  If set (at edge):
    LDA $192B
    INC A               ; Add 1 to position
    → CameraClampCheck
```

**Clamping Logic:**
```
Three paths to final position:

Path 1 (Base):
  Position = $192B (no modification)

Path 2 (Scrolled):
  Position = $192B + 8 (standard scroll)

Path 3 (Edge):
  Position = $192B + 1 (edge adjust)

All stored to $0A9C
```

**Coordinate System:**
```
Pixel coords ($1914): 0-511 (9-bit)
Tile coords ($192B): 0-31 (5-bit)
Conversion: pixel >> 4 (divide by 16)

Screen display: 16 tiles wide
Scroll range: 0-15 tiles offset
Total map: 32 tiles wide
```

**Side Effects:**
- Modifies `$192B` (intermediate position)
- Sets `$0A9C` (final camera position)
- Calls external bitfield routine

**Calls:**
- `CODE_009776` (JSL) - Bitfield check routine

**Called By:**
- Main camera update loop
- Scroll processing
- Screen transition handlers

**Related:**
- See `Field_CameraScroll` for disabling
- See `Field_CameraUpdate` for enabling
- See `Field_CameraClampY` for Y-axis equivalent

---

#### Field_ProcessNPCInteraction
**Location:** Bank $01 @ $E404  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Initialize NPC interaction state and prepare sprite display for dialogue.

**Inputs:**
- `$1A54` = Current interaction mode flags
- `$0CD0-$0CDC` = Source sprite data (8 bytes × 4 slots)

**Outputs:**
- `$0E06` = Cleared (interaction counter reset)
- `$0C60-$0C6E` = NPC sprite data copied (16 bytes)
- `$0C62, $0C66, $0C6A, $0C6E` = Tile indices set

**Technical Details:**
- Sets up 4 sprite slots for NPC dialogue portrait
- Copies sprite OAM data from source to display slots
- Assigns sequential tile indices starting at $70
- Uses 16-bit mode for efficient data transfer

**Process Flow:**
```
1. Reset interaction state:
   STZ $0E06                ; Clear counter

2. Build sprite mode byte:
   LDA #$0C                 ; Base mode
   ORA $1A54                ; Combine with flags
   XBA                      ; Move to high byte

3. Set base tile index:
   LDA #$70                 ; Starting tile

4. Save processor state:
   PHP                      ; Save status

5. Switch to 16-bit mode:
   REP #$30                 ; A and X/Y 16-bit

6. Assign tile indices:
   STA $0C62                ; Slot 0: Tile $70
   INC A
   STA $0C66                ; Slot 1: Tile $71
   INC A
   STA $0C6A                ; Slot 2: Tile $72
   INC A
   STA $0C6E                ; Slot 3: Tile $73

7. Copy sprite data (4 × 16-bit transfers):
   LDA $0CD0 → STA $0C60   ; Slot 0 position
   LDA $0CD4 → STA $0C64   ; Slot 1 position
   LDA $0CD8 → STA $0C68   ; Slot 2 position
   LDA $0CDC → STA $0C6C   ; Slot 3 position

8. Restore state:
   PLP                      ; Restore status
   RTS
```

**Sprite Slot Structure:**
```
Each slot: 4 words (8 bytes)
  
Slot 0 ($0C60-$0C63):
  $0C60: X position (word)
  $0C62: Tile index ($70)
  
Slot 1 ($0C64-$0C67):
  $0C64: X position (word)
  $0C66: Tile index ($71)
  
Slot 2 ($0C68-$0C6B):
  $0C68: X position (word)
  $0C6A: Tile index ($72)
  
Slot 3 ($0C6C-$0C6F):
  $0C6C: X position (word)
  $0C6E: Tile index ($73)
```

**Tile Layout (Dialogue Portrait):**
```
NPC face sprite uses 4 tiles:
  
  [Tile $70][Tile $71]  ← Top row
  [Tile $72][Tile $73]  ← Bottom row
  
  Each tile: 8×8 pixels
  Total portrait: 16×16 pixels
```

**Interaction Mode Flags ($1A54):**
```
Bit 0: Dialogue active
Bit 1: Shop mode
Bit 2: Cutscene mode
Bit 3: Inn interaction
Bits 4-7: Reserved

Combined with #$0C (base) via ORA
Stored in high byte via XBA
```

**Source Data ($0CD0-$0CDC):**
```
$0CD0: NPC sprite X (slot 0)
$0CD4: NPC sprite X (slot 1)
$0CD8: NPC sprite X (slot 2)
$0CDC: NPC sprite X (slot 3)

Copied verbatim to destination
Position data preserved from entity
```

**Side Effects:**
- Clears `$0E06` (interaction counter)
- Overwrites `$0C60-$0C6F` (16 bytes OAM data)
- Assigns tile indices $70-$73
- Preserves all registers (PHP/PLP)

**Calls:**
- None (direct register operations)

**Called By:**
- NPC interaction trigger routine
- Dialogue initialization
- Called 3 times in interaction sequence

**Related:**
- See `Field_CheckInteractionRange` for range checking
- See `Field_ValidateInteraction` for validation
- See `Field_TriggerNPCDialog` for dialogue trigger
- See OAM documentation for sprite structure

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

#### Cursor_UpdateComplete
**Location:** Bank $00 @ $8A9C  
**File:** `src/asm/banks/bank_00.asm`

**Purpose:** Validate cursor position after input processing - ensures cursor stays within grid bounds with configurable wrapping behavior.

**Inputs:**
- `$01` = Cursor row position (Y coordinate in grid)
- `$02` = Cursor column position (X coordinate in grid)
- `$03` = Maximum row count (grid height)
- `$04` = Maximum column count (grid width)
- `$95` = Wrapping behavior flags (bits 1-3)

**Outputs:**
- `$01` = Validated row position (clamped or wrapped)
- `$02` = Validated column position (clamped or wrapped)
- Cursor guaranteed within valid bounds

**Technical Details:**
- Called after directional input processing
- Handles grid boundary conditions
- Supports both clamping and wrapping modes
- Used in all menu cursor movement

**Process Flow:**
```
1. Check vertical (row) bounds:
   LDA $01       - Load current row
   BMI Wrap1     - If negative (< 0), handle wrap
   CMP $03       - Compare with max rows
   BCC Check_H   - If within bounds, check horizontal
   
2. Handle vertical out-of-bounds:
   If row < 0 OR row >= max_rows:
   
   Wrap1:
     LDA $95       - Load wrap flags
     AND #$02      - Check vertical wrap bit
     BNE Clamp_V   - If wrap disabled, clamp
     STZ $01       - Else wrap to 0
     BRA Check_H
   
   Clamp_V:
     LDA $03       - Load max rows
     DEC A         - Subtract 1 (0-based index)
     STA $01       - Store clamped value

3. Check horizontal (column) bounds:
   Check_H:
     LDA $02       - Load current column
     BMI Wrap2     - If negative, handle wrap
     CMP $04       - Compare with max columns
     BCC Complete  - If within bounds, done!
     
     LDA $95       - Load wrap flags
     AND #$04      - Check horizontal wrap bit
     BNE Clamp_H   - If wrap disabled, clamp
     BRA Wrap2     - Else wrap
   
   Clamp_H:
     LDA $04       - Load max columns
     DEC A         - Subtract 1 (0-based)
     STA $02       - Store clamped value
     RTS

4. Handle horizontal wrap:
   Wrap2:
     LDA $95       - Load wrap flags
     AND #$08      - Check horizontal wrap mode
     BNE Clamp_H   - If mode 2, clamp instead
     STZ $02       - Else wrap to 0

5. Complete:
   RTS
```

**Wrapping Behavior Flags:**
```
$95 = Wrapping configuration (8-bit flags)

Bit 1 (value $02): Vertical wrap enable
  0 = Wrap around (0 → max-1, max → 0)
  1 = Clamp to edges (no wrap)

Bit 2 (value $04): Horizontal wrap enable
  0 = Wrap around
  1 = Clamp to edges

Bit 3 (value $08): Horizontal wrap mode
  0 = Wrap to 0
  1 = Clamp to max-1

Examples:
  $95 = $00: Full wrapping (both axes)
  $95 = $02: Vertical clamp, horizontal wrap
  $95 = $06: Full clamping (no wrap)
  $95 = $0A: Vertical clamp, horizontal clamp
```

**Grid Bounds Validation:**
```
Valid positions:
  Row: 0 to ($03 - 1)
  Column: 0 to ($04 - 1)

Example 3×4 grid ($03 = 3, $04 = 4):
  Valid rows: 0, 1, 2
  Valid columns: 0, 1, 2, 3
  
  Cursor at (2, 3): Valid
  Cursor at (3, 0): Invalid (row >= max)
    → Clamped to (2, 0) or wrapped to (0, 0)
  Cursor at (1, 4): Invalid (col >= max)
    → Clamped to (1, 3) or wrapped to (1, 0)
  Cursor at (-1, 2): Invalid (row < 0)
    → Clamped to (0, 2) or wrapped to (2, 2)
```

**Typical Grid Sizes:**
```
Battle menu:
  $03 = 4 (Attack, Magic, Item, Defend)
  $04 = 1 (single column)

Item menu:
  $03 = 8 (8 items visible)
  $04 = 1 (single column)

Equipment menu:
  $03 = 5 (Weapon, Armor, Helm, Ring, Charm)
  $04 = 1 (single column)

Targeting (battle):
  $03 = 2 (2 rows of enemies)
  $04 = 4 (up to 4 enemies per row)
```

**Clamping vs Wrapping Examples:**
```
Clamping mode ($95 = $06):
  At top (row = 0), press UP:
    row = -1 → Clamped to 0 (no wrap)
  
  At bottom (row = max-1), press DOWN:
    row = max → Clamped to max-1

Wrapping mode ($95 = $00):
  At top (row = 0), press UP:
    row = -1 → Wrapped to max-1 (go to bottom)
  
  At bottom (row = max-1), press DOWN:
    row = max → Wrapped to 0 (go to top)
```

**Integration with Input:**
```
Input processing flow:

1. Input_ProcessDPad:
   - Detect directional input
   - Modify $01/$02 based on direction
   - May go out of bounds temporarily

2. Cursor_UpdateComplete (this function):
   - Validate modified position
   - Apply wrapping or clamping
   - Ensure valid coordinates

3. Cursor_UpdateSprite:
   - Render cursor at validated position
   - Update OAM entries
   - Apply visual effects

Example: Pressing DOWN in battle menu
  Current: row = 3 (Defend option, max)
  Input: DOWN pressed
  Modify: row = 4 (out of bounds!)
  Validate: Wrap or clamp to valid value
  Result: row = 0 (Attack) if wrapping
          row = 3 (Defend) if clamping
```

**Side Effects:**
- Modifies `$01` and `$02` (cursor position)
- No RAM clobbering beyond specified locations
- Minimal register usage (A only)

**Calls:**
- None (leaf function)

**Called By:**
- Menu input handlers after D-pad processing
- Battle menu cursor movement
- Item/equipment menu navigation
- Any grid-based selection interface

**Related:**
- See `Cursor_UpdateSprite` for cursor rendering
- See `Input_ProcessDPad` for directional input
- See menu-specific input handlers for integration

---

#### Cursor_UpdateSprite
**Location:** Bank $00 @ $8C3D  
**File:** `src/asm/banks/bank_00.asm`

**Purpose:** Render cursor sprite at current position - updates OAM (Object Attribute Memory) for visual cursor display in battle and field menus.

**Inputs:**
- `$1031` = Cursor grid position index (0-255, $FF = hidden)
- `$00D8` (bit 1) = Display mode (0 = field, 1 = battle)
- `$00DA` (bits 2, 4) = Cursor blink/flash state
- `$0014` = Animation timer
- DATA8_049800 (table) = Grid position to pixel conversion

**Outputs:**
- OAM entries updated ($7F075A+, $7E2D1A+)
- Cursor sprite rendered on screen
- Visual effects applied (palette, blink)

**Technical Details:**
- Handles both battle and field cursor styles
- Supports cursor hiding ($1031 = $FF)
- Applies blinking animation for emphasis
- Uses different sprite configurations per mode
- Updates 2-4 OAM entries for multi-tile cursor

**Process Flow:**
```
1. Save processor state:
   PHP           - Push processor flags
   SEP #$30      - 8-bit A, X, Y

2. Check if cursor visible:
   LDX $1031     - Load cursor position
   CPX #$FF      - Check for hidden marker
   BEQ Exit      - If $FF, cursor hidden, exit
   
3. Determine display mode:
   LDA #$02      - Bit mask for mode check
   AND $00D8     - Check display flags
   BEQ Field     - If clear, field mode
   
4A. Battle mode cursor ($00D8 bit 1 = 1):
   Battle cursor rendering:
   
   - Load pixel position:
     LDA DATA8_049800,X  - Get Y position
     ADC #$0A            - Offset for centering
     XBA                 - Swap to high byte
     
   - Calculate tile index:
     TXA                 - Transfer grid pos to A
     AND #$38            - Isolate row bits
     ASL A               - Multiply by 2
     PHA                 - Save
     TXA                 - Grid pos again
     AND #$07            - Isolate column bits
     ORA $01,S           - Combine with row
     PLX                 - Restore
     ASL A               - Final tile index
   
   - Update OAM (Bank $7F):
     REP #$30            - 16-bit mode
     STA $7F075A         - Tile 1 (top-left)
     INC A
     STA $7F075C         - Tile 2 (top-right)
     ADC #$000F          - Skip to next row
     STA $7F079A         - Tile 3 (bottom-left)
     INC A
     STA $7F079C         - Tile 4 (bottom-right)
   
   - Set attributes:
     SEP #$20            - 8-bit mode
     LDX #$17DA          - OAM attribute base
     LDA #$7F            - Bank for OAM
     BRA Set_Attr

4B. Field mode cursor ($00D8 bit 1 = 0):
   Field cursor rendering:
   
   - Calculate pixel position:
     LDA DATA8_049800,X  - Get base position
     ASL A (×2)          - Scale up
     ASL A (×2 again)
     STA $00F4           - Store scaled Y
   
   - Calculate tile index:
     REP #$10            - 16-bit index
     LDA $1031           - Load grid position
     JSR Cursor_CalcTileIndex  - Convert to tile
     STX $00F2           - Store tile index
   
   - Set attributes:
     LDX #$2D1A          - Field OAM base
     LDA #$7E            - Bank for OAM

5. Apply visual effects:
   Set_Attr:
     PHA                 - Save bank
     
   - Check for blink effect:
     LDA #$04            - Blink flag mask
     AND $00DA           - Check state
     BEQ Normal          - If not blinking, normal
     
     LDA $0014           - Load animation timer
     DEC A               - Decrement
     BEQ Normal          - If zero, normal frame
     
     - Apply blink palette:
       LDA #$10            - Palette flag
       AND $00DA           - Check blink mode
       BNE Blink2          - Different blink style
       
       PLB                 - Restore bank
       LDA $0001,X         - Load OAM attr
       AND #$E3            - Clear palette bits
       ORA #$94            - Palette 4 + priority
       BRA Set_Pal
   
   Blink2:
     PLB
     LDA $0001,X         - Load OAM attr
     AND #$E3            - Clear palette
     ORA #$9C            - Palette 5 + priority
     BRA Set_Pal
   
   Normal:
     PLB
     LDA $0001,X         - Load OAM attr
     AND #$E3            - Clear palette
     ORA #$88            - Palette 1 + priority

6. Handle special cases (multi-digit numbers):
   Set_Pal:
     XBA                 - Swap for later
     LDA $001031         - Load position again
     CMP #$29            - Check if numeric display
     BCC Simple          - If < $29, simple cursor
     CMP #$2C            - Check range
     BEQ Simple          - If $2C, simple
     
   - Multi-digit number display:
     LDA $0001,X         - OAM attribute
     AND #$63            - Clear priority/palette
     ORA #$08            - Set palette 0
     STA $0001,X         - Update tile 1
     STA $0003,X         - Update tile 2
     
     - Convert number to tiles:
       LDA $001030       - Load number value
       LDY #$FFFF        - Digit counter
       SEC
     
     Digit_Loop:
       INY               - Increment digit
       SBC #$0A          - Subtract 10
       BCS Digit_Loop    - Loop if >= 10
       
       ADC #$8A          - Convert to tile ID (ones)
       STA $0002,X       - Store ones digit
       
       CPY #$0000        - Check if tens digit
       BEQ Done          - If zero, no tens
       
       TYA               - Transfer tens
       ADC #$7F          - Convert to tile ID
       STA $0000,X       - Store tens digit
       BRA Done

7. Simple cursor update:
   Simple:
     XBA                 - Restore attribute
     STA $0001,X         - Update OAM attribute
     STA $0003,X         - Mirror for multi-tile

8. Complete:
   Done:
     PLP               - Restore processor state
     RTS
```

**Display Modes:**
```
Battle mode cursor ($00D8 bit 1 = 1):
  - Large 2×2 tile cursor (4 sprites)
  - Target selection visual
  - OAM Bank $7F (battle OAM buffer)
  - Positioned directly over enemies/allies
  
  Tiles used:
    $075A: Top-left tile
    $075C: Top-right tile
    $079A: Bottom-left tile
    $079C: Bottom-right tile

Field mode cursor ($00D8 bit 1 = 0):
  - Simple hand/arrow cursor (1-2 sprites)
  - Menu selection visual
  - OAM Bank $7E (field OAM buffer)
  - Positioned next to menu items
  
  Tiles used:
    $2D1A: Main cursor sprite
    (Additional tiles for multi-digit)
```

**OAM Structure:**
```
OAM entry format (4 bytes):
  Byte 0: X position (pixel coordinate)
  Byte 1: Y position (pixel coordinate)
  Byte 2: Tile index (character ID)
  Byte 3: Attributes (VhopppccT)
    V: Vertical flip
    h: Horizontal flip
    o: Priority (0-3)
    ppp: Palette (0-7)
    cc: Size bits
    T: Tile table select

Attribute byte breakdown:
  #$88: Priority 1, Palette 1
  #$94: Priority 1, Palette 4 (blink 1)
  #$9C: Priority 1, Palette 5 (blink 2)
```

**Grid Position to Pixel Conversion:**
```
DATA8_049800 table:
  Maps grid index to Y pixel position
  
  Index 0: Y = 16 pixels
  Index 1: Y = 32 pixels
  Index 2: Y = 48 pixels
  ...
  
Battle mode:
  Y_pixel = DATA8_049800[index] + 10
  (Extra offset for battle layout)

Field mode:
  Y_pixel = DATA8_049800[index] × 4
  (Scaled 4× for menu spacing)
```

**Blink Animation States:**
```
$00DA flags:
  Bit 2 (value $04): Blink enable
    0 = Normal display
    1 = Blinking active
    
  Bit 4 (value $10): Blink mode
    0 = Palette 4 blink (#$94)
    1 = Palette 5 blink (#$9C)

$0014: Animation timer
  Counts down each frame
  When = 1, blink frame activates
  When = 0, normal display

Blink cycle:
  Frame 0-14: Normal (#$88)
  Frame 15: Blink (#$94 or #$9C)
  Frame 0: Reset
```

**Multi-Digit Number Display:**
```
Used for quantity indicators (e.g., item counts)

$1030 = Number value (0-99)
$1031 >= $29: Enable number display

Process:
  1. Divide by 10 to get tens/ones
  2. Convert each digit to tile ID
  3. Display as two adjacent sprites
  
Example: Display "47"
  $1030 = 47
  
  tens = 47 / 10 = 4
  ones = 47 % 10 = 7
  
  Tile IDs:
    Tens: 4 + $7F = $83
    Ones: 7 + $8A = $91
  
  OAM:
    $0000,X = $83 (digit '4')
    $0002,X = $91 (digit '7')
```

**Side Effects:**
- Updates OAM entries in Bank $7E or $7F
- Modifies `$00F2`, `$00F4` (calculation buffers)
- Clobbers A, X, Y registers
- Changes processor state (SEP/REP)

**Calls:**
- `Cursor_CalcTileIndex` @ $8D8A - Grid to tile conversion (field mode)

**Called By:**
- Menu rendering loops (every frame)
- After cursor position changes
- Battle targeting updates
- Field menu display

**Related:**
- See `Cursor_UpdateComplete` for position validation
- See `Input_ProcessDPad` for cursor movement
- See OAM documentation for sprite details

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

### Collision Detection

#### Field_EntityCollision
**Location:** Bank $01 @ $8DF3  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Check for entity-to-entity collision and wait for collision processing to complete.

**Inputs:**
- `$1A46` = Collision processing flag

**Outputs:**
- Collision check complete
- `$1A46` cleared when done

**Technical Details:**
- Simple busy-wait loop that polls `$1A46`
- Used to synchronize collision processing with main game loop
- Preserves all processor flags and registers

**Process Flow:**
```asm
1. PHP                    ; Save processor status
2. SEP #$20, REP #$10    ; Set 8-bit A, 16-bit index
3. Loop:
   a. LDA $1A46          ; Load collision flag
   b. BNE Loop           ; If non-zero, keep waiting
4. PLP                   ; Restore processor status
5. RTS                   ; Return
```

**Collision Flag ($1A46):**
- `$00` = Collision processing complete
- `$01` = Entity collision in progress
- `$02` = Menu collision mode (from Menu_ProcessInput)
- Other values = Active collision processing

**Side Effects:**
- None (read-only, preserves all state)

**Called By:**
- `Field_UpdatePlayer` - Main player update loop
- `Menu_ProcessInput` - Menu scrolling collision
- Field movement routines

**Related:**
- See `Field_CheckEntityCollision` for actual collision logic
- See `Field_TileCollisionCheck` for tile-based collision
- See `Field_PlayerCollision` for player-specific handling

---

#### Field_CheckTileCollision
**Location:** Bank $01 @ $9038  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Check if a specific tile position is collidable by looking up collision flags in map data.

**Inputs:**
- `A` (low byte) = Tile index to check
- `X` = Tile offset (preserved)

**Outputs:**
- `A` (low byte) = Collision flags (bits 0-2)
- `A` (high byte) = Original tile index
- `X` = Unchanged (preserved)

**Technical Details:**
- Accesses collision data table at `$7FF274 + tile_index`
- Returns 3-bit collision value (0-7)
- Uses XBA to preserve tile index in high byte
- Fully reentrant with state preservation

**Process Flow:**
```asm
1. PHX                    ; Save X register
2. PHP                    ; Save processor status
3. SEP #$20, REP #$10    ; 8-bit A, 16-bit index
4. XBA, PHA              ; Swap and save A high byte
5. XBA                   ; Restore A low byte
6. REP #$30              ; 16-bit mode
7. AND #$00FF            ; Mask to tile index
8. TAX                   ; Use as index
9. LDA $7FF274,X         ; Load collision flags
10. AND #$0007           ; Extract bits 0-2
11. SEP #$20             ; Back to 8-bit
12. REP #$10             ; Keep index 16-bit
13. XBA                  ; Put flags in low byte
14. PLA, XBA             ; Restore original tile in high
15. PLP, PLX             ; Restore all state
16. RTS
```

**Collision Data Table ($7FF274):**
```
Base address in Bank $7F (WRAM)
Each byte contains collision info:
  Bits 0-2: Collision type (0-7)
    0 = Walkable
    1 = Blocked (wall/obstacle)
    2 = Water (requires Aqua Boots)
    3 = Lava (requires Lava Armor)
    4 = Ice (slippery movement)
    5 = Spikes (damage tile)
    6 = Pit (fall damage)
    7 = Special (script trigger)
  Bits 3-7: Additional flags (tile properties)
```

**Side Effects:**
- None (read-only operation)
- All registers preserved except A
- Stack balanced

**Called By:**
- `Field_TileCollisionLoop` - Bulk tile checking
- `Field_PlayerMovement` - Player movement validation
- Map transition logic

**Related:**
- See `Field_TileCollisionLoop` for coordinate processing
- See `Field_CheckEntityCollision` for entity collision
- See Map System documentation for tile structure

---

#### Field_TileCollisionLoop
**Location:** Bank $01 @ $9058  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Convert pixel coordinates to tile coordinates for collision checking.

**Inputs:**
- `$1900` = X position (16-bit)
- `$1902` = Y position (16-bit)

**Outputs:**
- `$19BD` = Tile X coordinate (0-31)
- `$19BF` = Tile Y coordinate (0-15)

**Technical Details:**
- Divides pixel positions by 16 to get tile coordinates
- Uses bitwise operations (LSR) instead of division
- Handles map wrapping for Y coordinate
- Optimized for SNES tile grid (16×16 pixels per tile)

**Process Flow:**
```asm
1. PHP                    ; Save status
2. REP #$30              ; 16-bit mode

3. Process X coordinate:
   LDA $1900             ; Load X position
   AND #$01F0            ; Mask bits 4-8 (16-496 range)
   LSR × 4               ; Divide by 16 (shift right 4 bits)
   STA $19BD             ; Store tile X (0-31)

4. Process Y coordinate:
   LDA $1902             ; Load Y position
   AND #$00F0            ; Mask bits 4-7 (16-240 range)
   LSR × 4               ; Divide by 16
   INC A                 ; Add 1 for camera offset
   AND #$000F            ; Wrap to 0-15 (vertical wrap)
   STA $19BF             ; Store tile Y

5. PLP                   ; Restore status
6. RTS
```

**Coordinate Masking:**
```
X position ($1900):
  Raw pixel value: 0-511
  AND #$01F0:  Keep bits 4-8 only
  Result range: 0-496 (aligned to 16)
  After LSR×4: 0-31 tiles

Y position ($1902):
  Raw pixel value: 0-255  
  AND #$00F0:  Keep bits 4-7 only
  Result range: 0-240 (aligned to 16)
  After LSR×4: 0-15 tiles
  After INC+AND: Wrapped to 0-15
```

**FFMQ Map Structure:**
- Maps are 32 tiles wide (512 pixels)
- Maps are 16 tiles tall (256 pixels)
- Each tile is 16×16 pixels
- Vertical wrapping enabled (AND #$0F)
- Horizontal handled separately

**Side Effects:**
- Modifies `$19BD` (tile X)
- Modifies `$19BF` (tile Y)

**Called By:**
- Collision detection routines
- Movement validation
- Tile property lookups

**Related:**
- See `Field_CheckTileCollision` for using these coordinates
- See `Field_TileCollisionCheck` for direction-based checking
- See Map System for tile layout

---

#### Field_CheckEntityCollision
**Location:** Bank $01 @ $90DD  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Check collision properties for a specific entity based on map collision data.

**Inputs:**
- `A` (low byte) = Entity offset/index
- `$19B5` = Base collision table address (16-bit)

**Outputs:**
- `A` = Collision flags for the entity
- `X` = Preserved

**Technical Details:**
- Looks up collision data from Bank $07 @ $B013
- Adds entity offset to base collision table address
- Returns single byte of collision properties
- Zero-extends the 8-bit index to 16-bit for addressing

**Process Flow:**
```asm
1. PHX                    ; Save X register
2. PHP                    ; Save processor status
3. REP #$30              ; 16-bit mode

4. PHA                   ; Save A
5. AND #$00FF            ; Zero-extend to 16-bit
6. CLC
7. ADC $19B5             ; Add base collision address
8. TAX                   ; Use as index
9. PLA                   ; Restore original A

10. SEP #$20             ; 8-bit A
11. REP #$10             ; 16-bit index
12. LDA $07B013,X        ; Load collision flags from Bank $07

13. PLP                  ; Restore status
14. PLX                  ; Restore X
15. RTS
```

**Collision Table Structure ($07:B013):**
```
Bank $07, offset $B013
Variable-length table indexed by:
  base_address ($19B5) + entity_offset (A)

Each byte contains entity collision properties:
  Bit 0: Solid (blocks movement)
  Bit 1: NPC interaction enabled
  Bit 2: Trigger event on contact
  Bit 3: Enemy encounter zone
  Bit 4: Damage on contact
  Bit 5: Push/pull interaction
  Bit 6: Special collision (stairs, doors)
  Bit 7: Reserved
```

**Base Address Usage ($19B5):**
- Points to current map's collision table
- Set during map loading
- Different for each map/area
- Allows per-map collision customization

**Side Effects:**
- None (read-only)
- All registers preserved except A

**Called By:**
- Entity movement validation
- NPC interaction checks
- Event trigger detection

**Related:**
- See `Field_EntityCollisionLoop` for processing multiple entities
- See `Field_CheckTileCollision` for tile-based collision
- See Map Loading for collision table setup

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

### Status Effect Processing

#### Battle_ProcessPoison
**Location:** Bank $02 @ $8532  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Process poison status for battle entity - loads entity context and returns status flags.

**Inputs:**
- `$8D` = Entity index (slot in battle)
- Direct page assumed to be battle context

**Outputs:**
- `A` (low byte) = Entity status flags (from `$10`)
- `A` (high byte) = Poison flags (from `$21`)
- Direct page context modified

**Technical Details:**
- Sets up entity context for poison checking
- Returns combined status information in A register
- Uses XBA (exchange bytes) for efficient 16-bit result
- Context established via direct page remapping

**Process Flow:**
```asm
1. PHD                           ; Save current direct page
2. JSR Battle_SetEntityContextEnemy ; Set DP to entity's data
   - Maps direct page to entity memory
   - Entity offset = $8D (input)
3. LDA $21                       ; Load poison status flags
4. XBA                           ; Swap to high byte
5. LDA $10                       ; Load general status flags
6. PLD                           ; Restore original direct page
7. RTS                           ; Return with A = [poison|status]
```

**Entity Status Structure ($10-$21):**
```
$10 (General Status):
  Bit 0: Alive/Dead
  Bit 1: Active in battle
  Bit 2: Target available
  Bit 3: Can act this turn
  Bit 4-7: Other status flags

$21 (Poison/Special Status):
  Bits 0-5: Poison level/type
  Bit 6: Poison active
  Bit 7: Permanent status flag
```

**Return Value Analysis:**
```
Combined A register (16-bit):
  High byte ($21): Poison status
  Low byte ($10): General status
  
Example values:
  $C001: Poison active ($C0) + alive ($01)
  $0001: No poison ($00) + alive ($01)  
  $8000: Permanent status, dead
```

**Side Effects:**
- Temporarily modifies direct page
- Preserves all other registers
- Read-only operation on entity data

**Calls:**
- `Battle_SetEntityContextEnemy` @ $8F2F - Map DP to entity

**Called By:**
- `Battle_CalculatePoisonDamage` - Before damage calc
- `Battle_CheckPoison` - Status verification
- Confusion targeting logic

**Related:**
- See `Battle_CalculatePoisonDamage` for damage application
- See `Battle_SetEntityContextEnemy` for context setup
- See `Battle_CheckPoison` for status checking

---

#### Battle_CalculatePoisonDamage
**Location:** Bank $02 @ $853D  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Calculate poison damage amount and determine if damage should be applied to entity.

**Inputs:**
- `$8B` = Damage calculation mode
  - `< $02`: Normal poison damage
  - `>= $02`: Skip poison (other status)
- `$DC` = Additional status flags
- `$3A` = Special condition value

**Outputs:**
- `$77` = Calculated damage amount (16-bit)
- Carry flag = Damage should be applied
- Zero flag = Special condition met

**Technical Details:**
- Early exits if not poison damage mode
- Checks multiple status conditions
- Always zeros $77 damage accumulator first
- Uses comparison to determine damage application

**Process Flow:**
```
1. Initialize damage:
   LDX #$0000
   STX $77                ; Zero damage accumulator

2. Check damage mode:
   LDA $8B
   CMP #$02               ; Mode 2+ = not poison
   BCS ApplyDamage        ; C=1: Skip to apply

3. Check immunity flags:
   LDA $DC
   AND #$C0               ; Check bits 6-7 (immunity)
   BNE SkipPoison         ; If set, no poison damage

4. Check special condition:
   LDA $3A
   CMP #$11               ; Special value check
   BEQ SkipPoison         ; If $11, skip

5. ApplyDamage:
   PHD                    ; Save DP
   JSR SetEntityContext   ; Load entity data
   LDA $21                ; Get poison severity
   XBA
   LDA $10                ; Get status
   PLD                    ; Restore DP
   INC A                  ; Increment for check
   BNE PoisonComplete     ; If not zero, continue

6. PoisonComplete:
   XBA                    ; Get poison byte
   AND #$C0               ; Check severity bits
   BEQ SkipPoison         ; If no severity, skip
   RTS                    ; Else return (apply damage)

7. SkipPoison:
   ; Fall through to sleep processing
```

**Poison Immunity ($DC flags):**
```
Bit 6: Temporary poison immunity
Bit 7: Permanent poison immunity

AND #$C0: Check both
  $C0: Full immunity
  $80: Permanent immunity  
  $40: Temporary immunity
  $00: No immunity (vulnerable)
```

**Poison Severity ($21 bits 6-7):**
```
Poison level extracted via AND #$C0:
  $00: No poison active
  $40: Light poison (1 damage per turn)
  $80: Medium poison (2-4 damage per turn)
  $C0: Heavy poison (5-8 damage per turn)
```

**Special Condition ($3A):**
```
Value $11: Special bypass condition
  - Certain battle states
  - Temporary invulnerability
  - Story-based immunity
  
If $3A == $11: Skip poison entirely
```

**Flow Control:**
```
Mode Check ($8B):
  < $02: Poison damage mode → Continue checks
  >= $02: Other status mode → Jump to apply

Immunity Check ($DC):
  AND #$C0 != $00: Immune → Skip to sleep
  AND #$C0 == $00: Vulnerable → Continue

Special Check ($3A):
  == $11: Special state → Skip to sleep
  != $11: Normal state → Apply damage

Final Check (return value):
  XBA, AND #$C0 == $00: No severity → Skip
  XBA, AND #$C0 != $00: Has severity → Apply (RTS)
```

**Side Effects:**
- Sets `$77` = $0000 (damage accumulator)
- May load entity context (modifies DP temporarily)

**Calls:**
- `Battle_SetEntityContextEnemy` @ $8F2F - Load entity data

**Called By:**
- `Battle_TargetFound` - During target processing loop
- Status effect processing routines

**Related:**
- See `Battle_ProcessPoison` for entity status loading
- See `Battle_ApplyPoisonDamage` for actual damage application
- See `Battle_ProcessSleep` for next status in chain

---

#### Battle_ProcessParalysis  
**Location:** Bank $02 @ $8486  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Handle paralysis status effect - check if entity can act and process paralysis duration/cure.

**Inputs:**
- `$11` = Entity action flags
- `$38` = Current status effect type
- `$3A` = Status duration/intensity value
- `$8D` = Current entity slot index
- `$90` = Entity comparison value

**Outputs:**
- `$8D` = Updated entity index (if paralyzed)
- `$8E` = Paralysis duration value
- `$DE` = Animation/effect type
- Jump to wake probability calculation if paralyzed

**Technical Details:**
- Checks action flag bit 0 (can act?)
- Processes different paralysis types by status value
- Handles both timed and conditional paralysis
- May trigger special paralysis animations

**Process Flow:**
```
1. Check if entity can act:
   LDA $11
   AND #$01                ; Bit 0: Can act this turn?
   BEQ CheckConfusion      ; If clear, skip paralysis

2. Check status type ($38):
   If $38 == $10:          ; Standard paralysis
     Check duration ($3A):
       If $3A >= $49 AND $3A < $50:
         ; Mid-duration paralysis
         Load animation data:
           LDX #$D2E4
           JSR $8835        ; Display paralysis effect
           LDX #$D46E  
           JSR $8835        ; Update status display
         Copy $8E → $8D
         Return
         
   If $38 == $20:          ; Triggered paralysis
     Skip (fallthrough)

3. CheckConfusion:
   ; Fall through to confusion processing
```

**Paralysis Types ($38 values):**
```
$10: Standard Paralysis
  - Cannot act for N turns
  - Duration tracked in $3A
  - Range check: $49-$4F (7 turn window)
  - Animation: Paralysis icon ($D2E4)

$20: Triggered Paralysis
  - Conditional on battle state
  - No duration tracking
  - Skips animation
  - Immediate processing

Other: Non-paralysis status
  - Fall through to confusion check
```

**Duration Ranges ($3A):**
```
$3A value meanings:
  $00-$48: No paralysis / expired
  $49-$4F: Active paralysis (7 turns max)
  $50+: Special/permanent paralysis
  
Duration check:
  CMP #$49: Below = expired
  BCC Skip
  CMP #$50: Above = special
  BCS Skip
  
  Valid range: $49 ≤ $3A < $50
```

**Animation References:**
```
LDX #$D2E4:
  - Points to paralysis icon tile data
  - Yellow/blue zigzag effect
  - Displayed over entity sprite

LDX #$D46E:
  - Status bar update data
  - Shows "PARA" text
  - Updates battle UI
```

**Entity Tracking:**
```
$8D (Current entity slot):
  - Input: Entity being checked
  - Output: Paralyzed entity (if applicable)
  - Copied from $8E after animation

$90 (Comparison entity):
  - Used for turn order
  - Compared with $8D
  - Affects turn processing
```

**Side Effects:**
- Modifies `$8D` (entity index) if paralyzed
- Sets `$8E` (temporary storage)
- Sets `$DE` (animation type)
- Calls animation display routines
- May modify `$8F` (entity comparison)

**Calls:**
- `$8835` (JSR) - Display animation (2 calls)
  - First: Paralysis effect
  - Second: Status UI update

**Called By:**
- `Battle_ProcessPetrify` - After petrification check
- Status effect processing chain

**Related:**
- See `Battle_CheckParalysis` for paralysis flag check
- See `Battle_WakeProbability` for cure chance
- See `Battle_CureParalysis` @ $97B8 for removal

---

#### Battle_CheckPoison
**Location:** Bank $02 @ $8522  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Central poison status processing - handles status animation, mute checking, and display refresh after poison damage.

**Inputs:**
- Battle state with poison applied
- All entity status flags updated
- Poison damage already calculated

**Outputs:**
- Status animation played
- Mute status checked
- Battle display refreshed  
- UI updated

**Technical Details:**
- Orchestrates multiple status effect subsystems
- Long calls to different banks for animations/display
- Ensures proper sequencing of status updates
- Final cleanup before returning to battle loop

**Process Flow:**
```
1. Process status animation:
   JSL Battle_ProcessStatusAnimation ; Bank $02:$ED05
   - Displays poison bubble effect
   - Updates sprite OAM
   - Plays status sound effect

2. Check and handle mute:
   JSR Battle_CheckMute             ; Bank $02:$8600
   - Verifies mute status
   - Updates action availability
   - May cure if item used

3. Refresh battle display:
   JSL Battle_RefreshBattleDisplay  ; Bank $02:$D149
   - Redraws HP/status bars
   - Updates entity sprites
   - Clears dirty flags

4. Update UI subsystem:
   JSL CODE_009B02                  ; Bank $00:$9B02
   - Final UI polish
   - Menu state sync
   - Input handling prep

5. Return to battle loop:
   RTS
```

**Subsystem Call Chain:**
```
Battle_CheckPoison (Bank $02) calls:

1. Battle_ProcessStatusAnimation @ $02:$ED05
   Location: Bank $02 @ $ED05
   Purpose: Poison bubble animation
   - Loads animation frame data
   - Updates sprite palette (green tint)
   - Triggers OAM update
   - Plays bubbling sound effect

2. Battle_CheckMute @ $02:$8600
   Location: Bank $02 @ $8600
   Purpose: Verify mute status
   - Checks $11 bit 2 (mute flag)
   - Updates action menu
   - Disables spells if muted

3. Battle_RefreshBattleDisplay @ $02:$D149
   Location: Bank $02 @ $D149
   Purpose: Redraw all battle elements
   - HP bar updates
   - Status icon refresh
   - Sprite position correction
   - Background tile updates

4. CODE_009B02 @ $00:$9B02
   Location: Bank $00 @ $9B02
   Purpose: Final UI synchronization
   - Menu cursor position
   - Input buffer clear
   - Frame timing adjustment
```

**Animation Sequence ($02:$ED05):**
```
Poison animation frames (60 FPS):
  Frame 0-3:   Small bubble rises
  Frame 4-7:   Medium bubble
  Frame 8-11:  Large bubble pops
  Frame 12-15: Damage number display
  
Palette effect:
  Entity palette OR #$02 (green tint)
  Duration: 16 frames
  Restore: Original palette
```

**Mute Check Logic ($02:$8600):**
```
LDA $11           ; Load action flags
AND #$04          ; Bit 2 = Mute status
BEQ NotMuted      ; If clear, can use magic
  
; If muted:
  LDA #$00
  STA $ActionMenu  ; Disable magic commands
  ; Update menu display
NotMuted:
  RTS
```

**Display Refresh ($02:$D149):**
```
Updates (in order):
  1. HP bar position ($0C00 VRAM)
  2. Status icons ($0D00 VRAM)
  3. Entity sprites (OAM)
  4. Background tiles (if needed)
  5. Color palettes (if changed)
  
DMA transfers queued:
  - HP bar graphics (32 bytes)
  - Status icons (16 bytes)
  - OAM data (544 bytes)
```

**UI Sync ($00:$9B02):**
```
Final tasks:
  - Clear $19A5 (input buffer)
  - Reset $19AC (animation counter)
  - Update $420B (DMA trigger)
  - Prepare for next frame
```

**Side Effects:**
- Triggers multiple DMA transfers
- Modifies VRAM data
- Updates OAM (Object Attribute Memory)
- Changes sprite palettes temporarily
- Clears input buffers
- Resets animation counters

**Calls:**
- `Battle_ProcessStatusAnimation` @ $02:$ED05 (JSL)
- `Battle_CheckMute` @ $02:$8600 (JSR)
- `Battle_RefreshBattleDisplay` @ $02:$D149 (JSL)
- `CODE_009B02` @ $00:$9B02 (JSL)

**Called By:**
- Poison damage application routines
- Status effect processing loop
- End of turn status updates

**Related:**
- See `Battle_ProcessPoison` for entity status loading
- See `Battle_CalculatePoisonDamage` for damage calculation  
- See `Battle_ApplyPoisonDamage` for damage application

---

## Sprite & Graphics Functions

### OAM Management

#### BattleSprite_UpdateOAM
**Location:** Bank $0B @ $8077  
**File:** `src/asm/bank_0B_documented.asm`

**Purpose:** Update Object Attribute Memory (OAM) for battle sprites - copies sprite data from RAM to OAM mirror for display.

**Inputs:**
- `$192D` = OAM table index (sprite slot 0-127)
- `$1A73,X` = Sprite X position (16-bit)
- `$1A75,X` = Sprite Y position (16-bit)
- `$1A77,X` = Sprite tile index (character number)
- `$1A79,X` = Sprite attributes (palette, flip, priority)
- `X` = Sprite data index

**Outputs:**
- OAM mirror updated at `$0C02+`
- Sprite ready for VBLANK DMA transfer

**Technical Details:**
- OAM (Object Attribute Memory) controls sprite display
- Mirror buffer updated during logic, transferred during VBLANK
- Each OAM entry is 4 words (8 bytes)
- Uses indexed addressing for sprite slots

**OAM Entry Structure:**
```
Word 0 ($0C02,Y): X Position (9 bits, bit 8 in high table)
Word 1 ($0C06,Y): Y Position (8 bits)
Word 2 ($0C0A,Y): Tile Index (character number)
Word 3 ($0C0E,Y): Attributes byte
  Bit 0-2: Palette number (0-7)
  Bit 3-4: Priority (0-3, 0=highest)
  Bit 5: Reserved
  Bit 6: X flip
  Bit 7: Y flip
```

**Process Flow:**
```
1. Load OAM table index from $192D
2. Mask to 8-bit value
3. Multiply by 4 (ASL twice):
   - Each OAM entry is 4 words
   - Index * 4 = byte offset

4. Look up base OAM address:
   - Read from DATA8_01A63A,X (Bank $01 table)
   - Table contains pre-calculated OAM offsets
   - Result in Y = destination address

5. Copy sprite data to OAM mirror:
   - $1A73,X → $0C02,Y (X position)
   - $1A75,X → $0C06,Y (Y position)
   - $1A77,X → $0C0A,Y (Tile index)
   - $1A79,X → $0C0E,Y (Attributes)

6. Exit (restore registers and return)
```

**OAM Address Table (DATA8_01A63A):**
```
Pre-calculated offsets for 128 sprite slots
Each entry points to:
  Slot 0:  $0C02 (offset $00)
  Slot 1:  $0C0A (offset $08)
  Slot 2:  $0C12 (offset $10)
  ...
  Slot 127: Last OAM entry
```

**Side Effects:**
- Updates OAM mirror at `$0C02-$0CFF` range
- Does NOT directly write to PPU
- Actual transfer happens during VBLANK via DMA

**Register Usage:**
```
Entry: 16-bit mode (REP #$30)
A: OAM index calculations
X: Sprite data index (preserved via PHX/PLX)
Y: OAM destination address
```

**Called By:**
- Battle sprite animation system
- Every frame for active battle sprites
- Sprite movement/animation routines

**Related:**
- See VBLANK DMA transfer routines for OAM upload
- See `$2102-$2104` (OAMADDL/OAMDATA) for PPU registers
- See sprite animation system for frame updates

---

### Sprite Animation

#### BattleSprite_Animate
**Location:** Bank $0B @ $803F  
**File:** `src/asm/bank_0B_documented.asm`

**Purpose:** Update sprite animation state and render animation frames.

**Inputs:**
- `$192B` = Sprite index (or $FFFF if no sprite)
- `$1A80,X` = Sprite attribute flags
- `$1A82,X` = Animation frame index

**Outputs:**
- Sprite animation advanced
- OAM data updated
- Graphics rendered

**Technical Details:**
- Called during VBLANK
- Manages sprite state transitions
- Coordinates with frame data tables
- Updates both logic and display

**Process Flow:**
```
1. Save processor state (PHP/PHB/PHX/PHY)
2. Set CPU modes:
   - SEP #$20 (8-bit A)
   - REP #$10 (16-bit X/Y)
3. Set data bank to $0B (PHK/PLB)

4. Call animation state setup:
   - JSR CODE_0B80D9
   - Prepares animation tables

5. Check sprite validity:
   - Load sprite index from $192B
   - Compare with $FFFF
   - Exit if no sprite active

6. Update sprite attributes:
   - Load current attributes ($1A80,X)
   - AND with $CF (clear palette bits 4-5)
   - OR with $10 (set palette 1)
   - Store back to $1A80,X

7. Load animation frame data:
   - Get frame index from $1A82,X
   - Multiply by 2 (word table)
   - Look up in DATA8_00FDCA (Bank $00)
   - Add $08 offset for alignment
   - Result in Y = frame data pointer

8. Render sprite:
   - JSL CODE_01AE86 (Bank $01)
   - Sprite rendering routine
   - Processes frame data
   - Updates graphics buffers

9. Update OAM:
   - Call BattleSprite_UpdateOAM
   - Copy data to OAM mirror
   - Prepare for VBLANK transfer

10. Restore state and return
```

**Animation Frame Table:**
```
Location: DATA8_00FDCA (Bank $00)
Format: Word table (16-bit pointers)
  Index 0: Frame 0 data address
  Index 1: Frame 1 data address
  ...
  
Frame Data Structure:
  +$00: Frame header
  +$08: Sprite data start (offset added)
  Data contains:
    - Tile patterns
    - Palette info
    - Position offsets
```

**Palette Management:**
```
Default: Clear bits 4-5 (AND $CF)
Set: OR with $10 (palette 1)

Palette Bits in Attributes:
  Bits 0-2: Primary palette (0-7)
  Bits 4-5: Extended palette flags
  
Final value determines CGRAM location
```

**Side Effects:**
- Modifies `$1A80,X` (sprite attributes)
- Updates animation state
- Calls rendering subsystems
- Updates OAM mirror
- Changes data bank register

**Calls:**
- `CODE_0B80D9` - Animation state setup
- `CODE_01AE86` @ Bank $01 - Sprite rendering
- `BattleSprite_UpdateOAM` - OAM update

**Called By:**
- Battle main loop
- VBLANK handler
- Sprite effect system

**Related:**
- See frame data tables in Bank $00
- See sprite rendering in Bank $01

---

## Battle Damage Modifiers

### Damage Calculation System

#### Battle_CalculateDamage (Bank $01)
**Location:** Bank $01 @ $C488  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Orchestrate complete damage calculation for battle actions - sets up base damage parameters and prepares for elemental/status modifiers.

**Inputs:**
- `$199D` (16-bit) = Source damage value (attack power, spell power, etc.)
- `$19EE` (byte) = Attack/spell type flags (bits 4-5 encode type)

**Outputs:**
- `$192D` (16-bit) = Final base damage value (before modifiers)
- `$192B` (byte) = Damage type classification (0-3)
- Ready for elemental/status processing

**Technical Details:**
- Minimal processing - primarily parameter extraction and storage
- Extracts damage type from bit-shifted flags
- Serves as entry point for damage calculation pipeline
- Works with both banks $01 and $02 implementations

**Process Flow:**
```
1. Set processor state:
   SEP #$20  - 8-bit accumulator
   REP #$10  - 16-bit index registers

2. Load and store damage value:
   LDX $199D  - Load source damage (16-bit)
   STX $192D  - Store as base damage

3. Extract damage type:
   LDA $19EE  - Load type flags
   AND #$30   - Isolate bits 4-5 (type field)
   LSR A (×4) - Shift right 4 positions
   STA $192B  - Store damage type (0-3)

4. Return:
   RTS
```

**Damage Type Classification:**
```
$192B values (from bits 4-5 of $19EE):
  0: Physical attack (weapon-based)
  1: Magic attack (spell-based)
  2: Special effect (status/utility)
  3: Fixed damage (no variance)

Type encoding in $19EE:
  Bits 4-5: Type field
    00 = Physical ($00)
    01 = Magic ($10)
    10 = Special ($20)
    11 = Fixed ($30)
  
  Other bits: Additional flags
```

**Memory Layout:**
```
$199D-$199E: Source damage (16-bit LE)
  Example: $199D = $50, $199E = $00 → 80 damage

$19EE: Type flags (8-bit)
  Example: $19EE = $10 → Magic attack (type 1)
  
$192D-$192E: Base damage output (16-bit LE)
  Copied directly from $199D-$199E

$192B: Damage type (8-bit)
  Extracted and shifted from $19EE
```

**Integration with Damage Pipeline:**
```
Full damage calculation flow:

1. Battle_CalculateDamage (this function)
   - Extract base damage and type
   - Store in calculation buffers

2. Battle_CalculateDamage (Bank $02 @ $93FD)
   - Apply attack vs defense
   - Calculate reduction
   - Apply variance

3. Battle_CheckCriticalHit
   - Determine critical hit
   - Apply 2× multiplier

4. Battle_ProcessElementalDamage
   - Elemental modifiers
   - Status effects

5. Battle_ApplyDamage
   - Subtract from target HP
   - Death check
   - Animation
```

**Comparison: Bank $01 vs Bank $02:**
```
Bank $01 @ $C488 (this function):
  - Parameter extraction
  - Type classification
  - Setup for modifiers
  - Returns immediately

Bank $02 @ $93FD (same name):
  - Attack vs defense calculation
  - Stat-based reduction
  - Variance application
  - More complex logic

Different functions, same name, different purposes.
```

**Side Effects:**
- Modifies `$192D-$192E` (base damage buffer)
- Modifies `$192B` (damage type)
- Sets processor flags (SEP/REP)
- No RAM clobbering outside specified locations

**Calls:**
- None (leaf function)

**Called By:**
- Battle action processing (Bank $01 @ $C21F, $C226, $C331)
- After attack power calculation
- Before status/elemental modifiers

**Related:**
- See `Battle_CalculateDamage` (Bank $02) for stat-based calculation
- See `Battle_CheckCriticalHit` for critical hit processing
- See `Battle_ProcessElementalDamage` for modifier application

---

#### Battle_CalculateDamage (Bank $02)
**Location:** Bank $02 @ $93FD  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Calculate damage reduction based on attack power vs defense - core stat-based damage formula applying defense mitigation.

**Inputs:**
- `$1116` (16-bit) = Attack power (weapon + stats + modifiers)
- `$1114` (16-bit) = Defense power (armor + stats + modifiers)
- Direct page = Battle context ($04xx for attacker/target)

**Outputs:**
- `$D1,X` (16-bit) = Final damage after defense reduction (indexed by `$8B × 2`)
- Carry flag = Set if attack > defense

**Technical Details:**
- Attack vs defense subtraction with clamping
- Damage capped to prevent overflow
- Negative results handled (minimum damage)
- Indexed storage for multi-target support

**Process Flow:**
```
1. Set processor state:
   REP #$30  - 16-bit A, X, Y

2. Calculate damage reduction:
   LDA $1116  - Load attack power
   SEC        - Set carry for subtraction
   SBC $1114  - Subtract defense
   
   Result:
     Positive: Attack > Defense, damage dealt
     Negative: Defense > Attack, minimum damage

3. Clamp to maximum:
   CMP DATA8_02D081  - Compare with max damage cap
   BCC Apply_Power   - If below cap, continue
   LDA DATA8_02D081  - Else load capped value

4. Invert for calculation:
   EOR #$FFFF  - Bitwise NOT
   INC A       - Two's complement negation
   BNE Reduce  - If non-zero, continue
   
   Special case (zero):
     DB $A9, $FE, $7F  - LDA #$7FFE
     (Load near-max value)

5. Store indexed result:
   TAY         - Transfer to Y for storage
   SEP #$20    - 8-bit accumulator
   REP #$10    - 16-bit index
   
   LDA #$00    - Clear high byte
   XBA         - Swap to clear A
   LDA $8B     - Load target index
   ASL A       - Multiply by 2 (16-bit index)
   TAX         - Transfer to X
   
   STY $D1,X   - Store damage at indexed location

6. Return:
   RTS
```

**Damage Calculation Formula:**
```
damage = attack - defense

If damage > MAX_DAMAGE_CAP:
  damage = MAX_DAMAGE_CAP
  
If damage <= 0:
  damage = MINIMUM_DAMAGE (usually 1-2)

Final = ~damage + 1  (two's complement)

Indexed storage:
  offset = target_index × 2
  $04D1[offset] = damage
```

**Data Structures:**
```
$1116-$1117: Attack power (16-bit LE)
  Example: Sword (50) + Strength (20) = 70
  
$1114-$1115: Defense power (16-bit LE)
  Example: Armor (30) + Vitality (15) = 45
  
Calculation: 70 - 45 = 25 damage

$04D1 array: Damage results (multi-target)
  $04D1 + (0 × 2) = Target 0 damage
  $04D1 + (1 × 2) = Target 1 damage
  $04D1 + (2 × 2) = Target 2 damage
  $04D1 + (3 × 2) = Target 3 damage
  
  16-bit values, indexed by $8B
```

**Damage Capping:**
```
MAX_DAMAGE_CAP = DATA8_02D081 (constant)
  Likely value: $7FFE (32766)
  Prevents overflow damage

Minimum damage:
  If attack <= defense:
    Apply minimum damage (1-2)
    Ensures attacks always do something
```

**Target Indexing:**
```
$8B = Current target index (0-7)
  0-3: Party members
  4-7: Enemies

Index calculation:
  $8B = 2 (target is party member 2)
  ASL A → 4 (multiply by 2)
  
  Storage: $04D1 + 4 = $04D5
  
Supports multi-target attacks:
  Loop through targets, calculate separately
  Each result stored at unique index
```

**Side Effects:**
- Modifies `$D1,X` indexed by target
- Clobbers A, X, Y registers
- Changes processor state (SEP #$20, REP #$10/30)
- Direct page assumed to be battle context

**Calls:**
- None (leaf function, data access only)

**Called By:**
- Battle action processing after power calculation
- Physical attack damage calculation
- Magic attack damage calculation (if applicable)

**Related:**
- See `Battle_CalculateDamage` (Bank $01) for parameter setup
- See `Battle_CheckCriticalHit` for critical hit multiplier
- See `Battle_ProcessElementalDamage` for elemental modifiers

---

#### Battle_CheckCriticalHit
**Location:** Bank $02 @ $9495  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Determine if an attack results in a critical hit using RNG-based probability check - doubles damage on success.

**Inputs:**
- `$DE` = Attack/spell type ID
- `$B7` = Critical hit threshold (base chance)
- `$00A8` = RNG modulo parameter (101 for 1% increments)
- `$2E` (via DP) = Entity status flags (bit 2 = critical immunity)

**Outputs:**
- Critical hit confirmed: JMP to `Battle_AnimationFrame` @ $9CCA
- Critical hit failed: RTS (return to caller)
- `$B9`, `$B8` = Random roll values (intermediate)

**Technical Details:**
- Uses double RNG roll for fairness (two random values)
- Critical hit = 2× damage multiplier
- Threshold comparison determines success
- Special attack type always crits (type $15)
- Status immunity check prevents crits

**Process Flow:**
```
1. Check for guaranteed critical:
   LDA $DE      - Load attack type
   CMP #$15     - Compare with special type
   BEQ Confirmed - If special, always crit
   
2. Prepare RNG:
   LSR $B7      - Halve threshold (balance)
   
3. Generate first random value:
   LDA #$65     - Load 101 (modulo value)
   STA $00A8    - Store to RNG parameter
   JSL $009783  - Call RNG_GenerateRandom
   LDA $00A9    - Load result (0-100)
   STA $B9      - Store first roll

4. Generate second random value:
   JSL $009783  - Call RNG_GenerateRandom again
   LDA $00A9    - Load result (0-100)
   STA $B8      - Store second roll

5. Compare threshold:
   LDA $B7      - Load threshold
   CMP $B8      - Compare with second roll
   BCS Confirmed - If threshold >= roll, crit!
   RTS          - Else return (no crit)

6. Check critical immunity (before #5):
   PHD          - Save direct page
   JSR Battle_SetEntityContextEnemy
   LDA $2E      - Load entity flags (DP)
   PLD          - Restore direct page
   AND #$04     - Check bit 2 (crit immunity)
   BEQ Continue - If clear, allow crit
   JMP $977F    - Else jump to non-crit handler

7. Critical hit confirmed:
Battle_CriticalHitConfirmed:
   JMP Battle_AnimationFrame @ $9CCA
   (Triggers 2× damage and special animation)
```

**Critical Hit Calculation:**
```
threshold = $B7 / 2  (halved for balance)

roll1 = RNG(101)  - First random (0-100)
roll2 = RNG(101)  - Second random (0-100)

if threshold >= roll2:
  CRITICAL HIT! (2× damage)
else:
  Normal hit

Example:
  threshold = 10 (5 after halving)
  roll1 = 45 (not used for comparison)
  roll2 = 3
  
  5 >= 3 → CRITICAL!
```

**RNG Integration:**
```
RNG_GenerateRandom @ $00:$9783:
  Input: $00A8 = modulo (101)
  Output: $00A9 = result (0-100)
  
  Uses LCG algorithm:
    seed = (seed × 5) + $3711 + frame
    result = seed % 101
  
Two calls ensure fairness:
  - Double roll prevents RNG manipulation
  - Each call updates seed
  - Frame counter adds entropy
```

**Critical Hit Types:**
```
Special attack ($DE = $15):
  - Always critical
  - No RNG check
  - Guaranteed 2× damage

Physical attacks:
  - RNG-based chance
  - Threshold from weapon/stats
  - Can be blocked by immunity

Status check (bit 2 of $2E):
  - Enemies with immunity flag
  - Bosses often have this
  - Jump to non-crit handler ($977F)
```

**Threshold Sources:**
```
$B7 = Critical threshold:
  - Weapon base crit rate
  - Character luck stat
  - Equipment bonuses
  - Battle effects (e.g., Focus)
  
Higher threshold = higher crit chance

Example values:
  5: ~2.5% chance (5/2 = 2.5, vs 0-100)
  20: ~10% chance (20/2 = 10, vs 0-100)
  40: ~20% chance (40/2 = 20, vs 0-100)
```

**Damage Multiplication:**
```
After critical confirmed:
  Jump to Battle_AnimationFrame
  
Animation handler:
  - Trigger critical hit animation
  - Apply 2× damage multiplier
  - Display "Critical!" text
  - Special sound effect
  
Damage flow:
  base_damage = 100
  is_critical = true
  
  final_damage = base_damage × 2 = 200
```

**Side Effects:**
- Modifies `$B7`, `$B9`, `$B8` (RNG rolls and threshold)
- Calls RNG twice (updates global RNG seed)
- May jump to animation handler (non-return)
- Clobbers A register

**Calls:**
- `RNG_GenerateRandom` @ $009783 (called twice) - RNG generation
- `Battle_SetEntityContextEnemy` @ $8F2F - Set entity DP
- `Battle_AnimationFrame` @ $9CCA (via JMP) - Critical animation

**Called By:**
- Battle damage calculation (after defense applied)
- Physical attack processing
- Weapon attack handlers

**Related:**
- See `RNG_GenerateRandom` (Bank $00 @ $9783) for RNG algorithm
- See `Battle_AnimationFrame` for critical hit animation
- See damage calculation pipeline for integration

---

### Elemental System

#### Battle_ProcessElementalDamage
**Location:** Bank $02 @ $94D6  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Process elemental damage modifiers - applies weakness, resistance, absorption, and nullification.

**Inputs:**
- `$77` = Base damage value (16-bit)
- `$BA` = Elemental multiplier (1-4)
- `$DE` = Attack/spell type
- `$11` = Target status/resistance flags
- `$21` = Target elemental flags

**Outputs:**
- `$77` = Modified damage value
- Elemental effects applied
- Status effects triggered

**Technical Details:**
- Handles all elemental interactions
- Supports multiple element types
- Manages special cases (absorb, nullify)
- Integrates with status system

**Elemental Types:**
```
Fire:    Weakness vs Ice, Weak vs Water
Ice:     Weakness vs Fire
Thunder: Weakness vs Earth
Water:   Weakness vs Fire
Earth:   Weakness vs Thunder
Wind:    Special interactions
Light:   Holy damage
Dark:    Shadow damage
```

**Process Flow:**
```
1. Check for death resistance:
   - JSR Battle_DeathResistCheck
   - Instant death immunity check

2. Determine spell/attack type:
   - Load $DE (attack type)
   - Compare with $17 (spell threshold)
   - Branch to appropriate handler

3. For spells ($DE >= $17):
   - JSR Battle_MuteApplied
   - Check if mute prevents casting
   - Skip to bonus if muted

4. For physical ($DE < $17):
   - JSR Battle_ProcessMuteSpell
   - Different mute handling

5. Apply elemental multiplier:
   - REP #$20 (16-bit mode)
   - Load multiplier from $BA
   - Load base damage from $77
   - Loop: Add damage × multiplier times
     LDX $BA
     Loop:
       DEX
       BEQ Done
       CLC
       ADC $77
       BRA Loop
   - Store result back to $77

6. Special attack handling:
   - Check if $DE == $16
   - If yes: Keep full damage
   - If no: Halve damage (LSR A)

7. Apply weakness/resistance:
   - Check target flags ($11, $21)
   - Call weakness detection
   - Call resistance detection
   - Call absorption detection
   - Call nullification detection

8. Final processing:
   - JSR Battle_ReflectSpell (check reflect)
   - JMP Battle_ProcessPetrifySpell (petrify)
```

**Elemental Multiplier System:**
```
$BA = Multiplier value (1-4)

Value 1: Normal damage (×1)
Value 2: Weakness (×2)
Value 3: Greater weakness (×3)
Value 4: Critical weakness (×4)

Damage calculation:
  result = base_damage × multiplier
  
Implementation:
  Start with base_damage
  Add base_damage (multiplier - 1) times
```

**Special Cases:**
```
Absorb ($11 bit 3 set):
  - Damage becomes healing
  - Convert to HP restoration
  - Check target max HP
  - Display healing number

Nullify (resistance flags):
  - Damage reduced to 0
  - Display "Miss" or "No effect"
  - No status effects applied

Reflect (reflect flag set):
  - Spell bounces back to caster
  - Recalculate with new target
  - Apply to original caster
```

**Side Effects:**
- Modifies `$77` (damage value)
- May trigger status effects
- Updates battle state
- Calls multiple subsystems

**Calls:**
- `Battle_DeathResistCheck` @ $999D - Death immunity
- `Battle_MuteApplied` @ $9B34 - Mute check (spells)
- `Battle_ProcessMuteSpell` @ $9B28 - Mute check (physical)
- `Battle_CurePoison` @ $97B2 - Poison status handling
- `Battle_ReflectSpell` @ $9BED - Spell reflection
- `Battle_ProcessPetrifySpell` @ $99DA - Petrification

**Called By:**
- Damage calculation system
- After base damage determined
- Before final damage application

**Related:**
- See `Battle_CheckWeaknessFlags` for weakness detection
- See elemental data tables for element definitions

---

#### Battle_CheckWeaknessFlags
**Location:** Bank $02 @ $A97F  
**File:** `src/asm/banks/bank_02.asm`

**Purpose:** Check target's elemental weakness flags and apply appropriate damage modifiers.

**Inputs:**
- `$21` = Target elemental resistance/weakness flags
- Target entity data (via direct page)

**Outputs:**
- `$51` = Weakness flag ($81 normal, $80 double weakness)
- Weakness detection complete

**Technical Details:**
- Examines elemental affinity flags
- Determines weakness level
- Sets multiplier flags
- Part of damage calculation chain

**Weakness Flag Structure:**
```
$21 (Target Elemental Flags):
  Bit 0: Fire weakness
  Bit 1: Ice weakness
  Bit 2: Thunder weakness
  Bit 3: Absorb flag (special)
  Bit 4: Water weakness
  Bit 5: Earth weakness
  Bit 6: Wind weakness
  Bit 7: Reserved

$51 (Weakness Result):
  $81 = Normal weakness (×2 damage)
  $80 = Critical weakness (×4 damage)
```

**Process Flow:**
```
1. Save direct page (PHD)
2. Set entity context:
   - JSR Battle_SetEntityContextParty
   - Load target data to direct page

3. Set default weakness flag:
   - LDA #$81
   - STA $51
   - Assume normal weakness

4. Check for absorb flag:
   - LDA $21
   - AND #$08 (bit 3)
   - BEQ WeaknessFound
   - If bit 3 set → Absorb element

5. If absorb flag set:
   - LDA #$02
   - STA $00A8 (function parameter)
   - JSL CODE_009783 (element check)
   - LDA $00A9 (result)
   - BEQ WeaknessFound
   - If match: Absorb applies

6. If absorb matches:
   - LDA #$80
   - STA $51
   - Set critical weakness flag

7. Restore and return:
   - PLD (restore direct page)
   - RTS
```

**Weakness Levels:**
```
Normal Weakness ($51 = $81):
  - Standard elemental weakness
  - Damage ×2
  - Common for opposed elements

Critical Weakness ($51 = $80):
  - Enhanced weakness
  - Damage ×4
  - Rare, usually scripted encounters
```

**Elemental Relationships:**
```
Fire weak to: Ice, Water
Ice weak to: Fire
Thunder weak to: Earth
Earth weak to: Thunder
Water weak to: Thunder
Wind: Variable

Special: Some enemies weak to specific elements
```

**Side Effects:**
- Modifies `$51` (weakness flag)
- Changes direct page context
- Calls element checking routine
- Updates `$00A8-$00A9` (function parameters)

**Calls:**
- `Battle_SetEntityContextParty` @ $8F22 - Set target context
- `CODE_009783` @ Bank $00 - Element checking routine

**Called By:**
- `Battle_ProcessElementalDamage` - During damage calculation
- Elemental attack processing

**Related:**
- See `Battle_ProcessWeakness` for weakness application
- See `Battle_ApplyWeaknessMultiplier` for final multiplier

---

## Sound System Functions

### SPC700 Initialization

#### SPC_InitMain
**Location:** Bank $0D @ $802C  
**File:** `src/asm/bank_0D_documented.asm`

**Purpose:** Upload SPC700 sound driver to audio processor and initialize audio system - foundational routine for all FFMQ audio functionality.

**Inputs:**
- None (reads driver data from Bank $0D tables)
- DATA8_0D8008: Module count/header
- DATA8_0D8009: Module pointer table
- DATA8_0D8014-8015: Module size table

**Outputs:**
- SPC700 loaded with sound driver at $0200+ in SPC RAM
- SPC700 executing audio driver code
- APU ports ready for music/SFX commands
- `$0648` = Driver checksum (warm start detection)
- `$06F8` = Driver validation flag

**Technical Details:**
- **Protocol:** IPL (Initial Program Loader) handshake
- **APU Ports:** $2140-$2143 for bidirectional communication
- **Upload Target:** SPC700 RAM starting at $0200
- **Driver Size:** Multiple modules, ~4-6KB total
- **Timing:** ~200ms upload time (first boot)
- **Warm Start:** Detects existing driver, skips reload

**Process Flow:**
```
1. Save CPU state (PHB/PHD/PHP/registers)
2. Set data bank = $00, direct page = $0600

3. Check for SPC700 IPL ready signal:
   - Read $2140/$2141 (APUIO0/1)
   - Wait for $BBAA signature from SPC700 IPL ROM
   - If found → SPC700 ready for upload

4. Warm start detection:
   - Check $06F8 for checksum
   - Compare with $0648
   - If valid + $0600 = $F0 → Driver already loaded
   - Send reset command ($08 to $2141)
   - Skip full upload (saves ~200ms)

5. IPL handshake protocol:
   - Send module address to $2142/$2143 (16-bit)
   - Send command $01 to $2141 (upload mode)
   - Send $CC to $2140 (initial handshake)
   - Wait for SPC700 to echo $CC back
   - Handshake confirmed → Ready for data

6. Transfer each module:
   - Read module pointer from table
   - Read module size (first 2 bytes)
   - Loop through all bytes:
     * Send byte to $2141
     * Increment handshake ($CC→$CD→$CE...)
     * Send handshake to $2140
     * Wait for echo confirmation
   - Handshake wraps $00→$FF→$00 for sync

7. Start execution:
   - All modules uploaded
   - Send start address $0200 to $2142/$2143
   - Send $00 to $2141 (run command)
   - SPC700 begins driver execution

8. Restore CPU state and return
```

**IPL Handshake Details:**
```
Main CPU (65816)          SPC700 (IPL)
─────────────────         ─────────────
Write $CC → $2140    →    Read $2140
                     ←    Write $CC → $2140 (echo)
Read $2140 = $CC     ←    
Write byte → $2141   →    Read $2141 (data)
Write $CD → $2140    →    Read $2140 (sync)
                     ←    Write $CD → $2140 (echo)
Read $2140 = $CD     ←    
Write byte → $2141   →    [repeat for all bytes]
Write $CE → $2140    →    
...                  ...
```

**Module Upload Format:**
```
Each module in ROM:
  Offset +0: Size low byte
  Offset +1: Size high byte
  Offset +2 onward: Driver code/data

Module table entries:
  DATA8_0D8008: Module count (varies)
  DATA8_0D8009+: Pointers to modules (16-bit offsets)
  DATA8_0D8014+: Load addresses (SPC700 RAM)

Example:
  Module 0: $0286 bytes at $0D8686 → SPC $0200
  Module 1: $00AC bytes at $0D890E → SPC $0486
  (etc. for remaining modules)
```

**Warm Start Optimization:**
```
Check sequence:
  1. LDA $06F8 (checksum stored)
  2. BEQ → Not loaded, full upload
  3. CMP $0648
  4. BNE → Mismatch, full upload
  5. LDA #$F0
  6. CMP $0600
  7. BNE → Not ready, full upload
  8. All checks pass → Send reset command only

Reset command (warm start):
  $08 → $2141  ; Reset opcode
  $00 → $2140  ; Execute
  Wait for confirmation
  Driver resets, skips ~200ms upload
```

**SPC700 RAM Layout (Post-Upload):**
```
$0000-$00EF  : Zero page (driver variables)
$00F0-$00FF  : IPL ROM area (preserved)
$0100-$01FF  : Stack
$0200-$04FF  : Sound driver code (~768 bytes)
$0500-$07FF  : Driver data tables
$0800-$0FFF  : Music sequence buffer
$1000-$5FFF  : Sample data (BRR format)
$6000-$BFFF  : Additional samples
$C000-$EFFF  : Echo buffer (reverb)
$F000-$FFFF  : Driver extensions / work RAM
```

**Side Effects:**
- Writes to $2140-$2143 (APU I/O ports) - hundreds of writes
- Modifies direct page $0600-$06FF (work RAM)
- Updates $0648 (checksum storage)
- Updates $06F8 (validation flag)
- Changes data bank to $00
- Changes direct page to $0600
- Takes ~200ms first boot, ~10ms warm start
- Enables SPC700 audio interrupts
- Resets all 8 DSP voices

**Register Usage:**
```
Entry:  Any state (preserved via stack)
Work:   A=8-bit data/commands
        X=16-bit module offsets
        Y=16-bit byte offsets
        DP=$14-$16 = 24-bit ROM pointer
        DP=$10-$11 = Module size counter
Exit:   All registers restored (PLY/PLX/PLA)
```

**Calls:**
- (None - self-contained upload routine)

**Called By:**
- Game initialization (startup)
- Post-reset initialization
- Audio system restart (rare)

**Related:**
- See `CODE_0D8147` - APU command handler (music/SFX playback)
- See `docs/SOUND_SYSTEM.md` - Complete audio architecture
- See Bank $0F - Music/sample data
- See SPC700 IPL ROM documentation

---

### Audio Command Processing

#### APU_SendCommand
**Location:** Bank $0D @ $8147  
**File:** `src/asm/bank_0D_documented.asm`

**Purpose:** Send commands to initialized SPC700 driver for music playback, sound effects, volume control, and audio system management.

**Inputs:**
- `$0600` = Command byte (see command table below)
- `$0601` = Track/SFX ID (for commands $01/$03)
- `$0602-$0603` = Parameter word (varies by command)
- Additional parameters at $0604+ (command-specific)

**Outputs:**
- Command executed on SPC700
- `$0600` = $00 (cleared after processing)
- `$0605` = Current track ID (updated for $01)
- Audio playback state changed per command

**Technical Details:**
- **Entry Points:** CODE_0D8147 (main), CODE_0D8004 (wrapper)
- **Protocol:** Polling-based communication via APU ports
- **Latency:** ~1-3 frames for command acknowledgment
- **Capacity:** 256 possible commands ($00-$FF)

**Command Types:**
```
$00       : NOP - No operation (immediate return)
$01       : Load/play music track
$03       : Play sound effect (SFX)
$70-$7F   : Advanced commands (volume, pitch, tempo)
$80-$EF   : System commands (reserved/extended)
$F0-$FF   : System commands (reset, mute, stop)
```

**Command $01 - Load/Play Music:**
```
Inputs:
  $0601 = Track ID (0-29, varies by game)
  $0602-$0603 = Music data pointer (16-bit, optional)
  
Process:
  1. Check if same track already playing ($0605)
  2. If different or params changed:
     - Transfer music sequence data to SPC700
     - Set up playback parameters
     - Start music sequencer
  3. Update $0605 with new track ID
  
SPC700 Side:
  - Receives track data via $2141-$2143
  - Loads patterns, instruments, tempo
  - Starts 8-channel sequencer
  - Begins playback immediately
```

**Command $03 - Play Sound Effect:**
```
Inputs:
  $0601 = SFX ID (0-127 typical range)
  $0602 = Priority (0-15, higher = interrupt music)
  $0603 = Volume (0-255, $FF = full)
  
Process:
  1. Check SFX priority vs current playback
  2. Allocate free voice or steal lowest priority
  3. Transfer sample data if not cached
  4. Trigger one-shot or looped playback
  
Voice Allocation:
  - Channels 5-7 typically reserved for SFX
  - Music channels 0-4 can be stolen (high priority)
  - Voice stealing uses priority + age algorithm
```

**Advanced Commands ($70+):**
```
$70 : Set master volume (0-255)
$71 : Set music volume (0-255)
$72 : Set SFX volume (0-255)
$73 : Fade out music (duration in frames)
$74 : Fade in music (duration in frames)
$75 : Set tempo (50-200%, 100 = normal)
$76 : Set pitch shift (-12 to +12 semitones)
$77 : Enable/disable echo/reverb
$78 : Set echo parameters (delay, feedback, volume)
$79-$7F : Reserved/game-specific
```

**System Commands ($F0+):**
```
$F0 : Stop all audio (immediate silence)
$F1 : Pause music (resume with $F2)
$F2 : Resume paused music
$F3 : Reset SPC700 (soft reset, no driver reload)
$F4 : Mute all channels
$F5 : Unmute all channels
$F6-$FF : Reserved/extended functions
```

**Process Flow:**
```
1. Save CPU state (PHB/PHD/PHP/registers)
2. Set data bank = $00, direct page = $0600

3. Read command byte from $0600
4. Clear $0600 (mark command processed)
5. If $00 → Return immediately (NOP)

6. Dispatch based on command value:
   - $01 or $03 → CODE_0D8183 (music/SFX)
   - $80+ → CODE_0D8172 (system commands)
   - $70+ → CODE_0D8175 (advanced commands)
   - Other → Return (unsupported)

7. Execute command handler:
   - Music/SFX: Transfer data via APU ports
   - Volume: Send parameter to SPC700
   - System: Send control byte sequence

8. Wait for SPC700 acknowledgment (poll $2140)
9. Restore CPU state and return
```

**Music Load Optimization:**
```
Same track check:
  LDA $0601      ; New track ID
  CMP $0605      ; Current track ID
  BNE LoadNew    ; Different → Full load
  
  LDX $0602      ; Check parameters
  STX $0606
  CPX $0608      ; Compare with current
  BNE LoadNew    ; Changed → Reload
  
  RTS            ; Same track+params → Skip (already playing)

LoadNew:
  ; Full music load sequence
  ; Transfer ~1-4KB of sequence data
  ; Takes ~10-50ms depending on track size
```

**APU Communication Pattern:**
```
Send Command:
  1. Write command to $2140
  2. Write param1 to $2141
  3. Write param2 to $2142
  4. Write param3 to $2143
  5. Poll $2140 until SPC700 echoes command

Wait Acknowledgment:
  Loop:
    LDA $2140
    CMP <expected>
    BNE Loop
  ; Confirmed → Continue

Data Transfer (for music/SFX):
  For each byte:
    Write byte → $2141
    Increment handshake → $2140
    Wait for echo
  ; Full track uploaded
```

**Side Effects:**
- Writes to $2140-$2143 (APU I/O ports) - variable count
- Modifies direct page $0600-$060F (command buffer)
- Updates $0605 (current track ID)
- Updates $0606-$0609 (parameter cache)
- Changes data bank to $00
- Changes direct page to $0600
- Timing varies: NOP ~10 cycles, Music load ~10-50ms
- May interrupt currently playing audio
- SFX can steal music channels (high priority)

**Register Usage:**
```
Entry:  Any state (preserved via stack)
Work:   A=8-bit commands/data
        X=16-bit pointers/parameters
        Y=16-bit loop counters
        DP=$00-$0F = Command parameters
Exit:   All registers restored
```

**Calls:**
- CODE_0D8183 - Music/SFX loader
- CODE_0D8172 - System command handler
- CODE_0D8175 - Advanced command handler
- CODE_0D85BA - Extended system handler
- CODE_0D860E - Extended advanced handler

**Called By:**
- Battle system (damage SFX, victory music)
- Field system (walking SFX, interaction sounds)
- Menu system (cursor, select sounds)
- Cutscenes (music changes, dramatic SFX)
- Event scripts (scripted audio cues)

**Related:**
- See `SPC_InitMain` - Driver initialization
- See `docs/SOUND_SYSTEM.md` - Audio architecture
- See Bank $0F - Music and sample data

---

### Sprite Animation

#### Display_WaitVBlankAndUpdate
**Location:** Bank $0C @ $85DB  
**File:** `src/asm/bank_0C_documented.asm`

**Purpose:** Primary VBLANK synchronization with sprite animation update - performance-critical routine called hundreds of times per second to coordinate frame timing and animate sprite tiles.

**Inputs:**
- `$0E97` = Animation timer (frame counter)
- `$0202-$020B` = Sprite frame indices (5 sprites, word each)
- `$020C` = Sprite loop counter (internal)
- `$020E` = Sprite index (internal)
- DATA8_0C8659 = Animation frame table (14 frames)

**Outputs:**
- VBLANK synchronized (safe for VRAM/OAM updates)
- Sprite tiles updated in OAM buffer ($0C80+)
- Animation frames advanced (every 4 game frames)
- `$0CC2-$0CCE` = Updated sprite tile numbers
- `$0C94+` = Updated sprite pattern data

**Technical Details:**
- **Timing:** Called every game frame (~16.67ms NTSC, 20ms PAL)
- **Animation:** Updates every 4 frames (4:1 ratio, ~15 FPS sprite animation)
- **Sprites:** Handles 5 animated sprites simultaneously
- **Frames:** 14-frame animation cycle (wraps at frame 14)
- **Tiles:** Alternates between tile pairs ($4C/$4E, $48, $6C/$6E)

**Process Flow:**
```
1. Set data bank = current bank (PHK/PLB)
2. Save X register

3. Calculate animated tile numbers:
   - Read $0E97 (animation timer)
   - AND #$04 (test bit 2 = every 4 frames)
   - LSR (shift to bit 1)
   - ADC #$4C (base tile $4C or $4E)
   - Store to $0CC2, $0CCA (sprites 1, 2)
   - EOR #$02 (toggle $4C↔$4E)
   - Store to $0CC6, $0CCE (sprites 3, 4)

4. Setup sprite update loop:
   - Loop counter = 5 sprites
   - Sprite index = 0

5. For each sprite (loop 5 times):
   a) Calculate OAM pointer:
      - Index * 2 + $0C80 → Y (OAM buffer address)
   
   b) Advance animation frame:
      - Load current frame from $0202,X
      - Increment frame
      - If frame >= 14 → Wrap to 0
      - Store new frame back to $0202,X
   
   c) Update sprite tile:
      - Use frame as index into DATA8_0C8659
      - Load tile number from table
      - Store to OAM buffer ($0002,Y)
   
   d) Update sprite patterns (conditional):
      - If tile = $44:
        * Use pattern $6C for position 1
        * Use pattern $6E for position 2
      - Else:
        * Use pattern $48 for both positions
      - Calculate pattern pointer (index*4 + $0C94)
      - Store patterns to OAM buffer
   
   e) Loop housekeeping:
      - Increment sprite index by 2 (word addressing)
      - Decrement loop counter
      - Branch if not done

6. Update PPU registers (JSR CODE_0C8910)
7. Restore X register and return
```

**Animation Frame Table:**
```
DATA8_0C8659 (14 frames):
  Frame  0: Tile $00
  Frame  1: Tile $04
  Frame  2: Tile $04
  Frame  3: Tile $00
  Frame  4: Tile $00
  Frame  5: Tile $08
  Frame  6: Tile $08
  Frame  7: Tile $08
  Frame  8: Tile $0C
  Frame  9: Tile $40
  Frame 10: Tile $40
  Frame 11: Tile $44  ← Special (triggers $6C/$6E patterns)
  Frame 12: Tile $44
  Frame 13: Tile $00

14-frame cycle = ~933ms per loop at 15 FPS
```

**Tile Pattern Logic:**
```
Tile $44 Check:
  CMP #$44
  PHP              ; Save result
  ; ... (calculate pattern pointer)
  PLP              ; Restore result
  BEQ UseTile6C    ; Branch if tile was $44
  
  ; Default case (tile != $44):
  Pattern1 = $48
  Pattern2 = $48
  
  ; Special case (tile == $44):
UseTile6C:
  Pattern1 = $6C
  Pattern2 = $6E
  
Sprite Pattern Addresses:
  Base = $0C94 + (sprite_index * 4)
  +$00: [header byte]
  +$02: Pattern 1 tile
  +$06: Pattern 2 tile
```

**Animation Timing:**
```
Frame Counter ($0E97):
  Increments every game frame
  Animation check: Bit 2 (every 4 frames)
  
  Frame    $0E97    Bit 2    Update?
  ─────    ─────    ─────    ───────
    0      $00       0         No
    1      $01       0         No
    2      $02       0         No
    3      $03       0         No
    4      $04       1        Yes  ← Tile $4C
    5      $05       1        Yes
    6      $06       1        Yes
    7      $07       1        Yes
    8      $08       0         No  ← Tile $4E
    
  Result: Tile alternates every 4 frames
  Sprite frame advances every 4 frames
  Effective sprite animation: 15 FPS (60÷4)
```

**OAM Buffer Layout:**
```
Base: $0C80 (OAM mirror in WRAM)

Sprite 0: $0C80-$0C83 (4 bytes)
  +$00: X position
  +$01: Y position
  +$02: Tile number  ← Updated by this function
  +$03: Attributes

Sprite 1: $0C82-$0C85
Sprite 2: $0C84-$0C87
Sprite 3: $0C86-$0C89
Sprite 4: $0C88-$0C8B

Pattern buffer: $0C94+ (4 bytes per sprite)
  Sprite 0: $0C94-$0C97
  Sprite 1: $0C98-$0C9B
  Sprite 2: $0C9C-$0C9F
  Sprite 3: $0CA0-$0CA3
  Sprite 4: $0CA4-$0CA7
```

**Performance Analysis:**
```
Per-frame cost (all 5 sprites):
  Setup:           ~40 cycles
  Loop iteration:  ~120 cycles per sprite
  Total loop:      ~600 cycles (5 sprites)
  PPU update:      ~50 cycles
  Total:           ~690 cycles per frame
  
  Percentage of frame: 690 / 178,000 ≈ 0.4% (NTSC, 3.58 MHz)
  
Animation update (every 4th frame):
  Adds ~100 cycles for tile calculations
  Total: ~790 cycles
  Still only ~0.44% of frame budget
```

**Side Effects:**
- Modifies `$0CC2` (sprite 1 tile number)
- Modifies `$0CCA` (sprite 2 tile number)
- Modifies `$0CC6` (sprite 3 tile number)
- Modifies `$0CCE` (sprite 4 tile number)
- Updates `$0202-$020B` (all 5 sprite frame indices)
- Writes to OAM buffer $0C80-$0C8B (sprite tiles)
- Writes to pattern buffer $0C94+ (sprite patterns)
- Changes data bank to current bank ($0C)
- Calls CODE_0C8910 (PPU register update)
- Safe for VBLANK usage (enables VRAM/OAM transfers)

**Register Usage:**
```
Entry:  Any A/X/Y state
Work:   A=8/16-bit (tile data, counters)
        X=16-bit (sprite indices, loop)
        Y=16-bit (OAM buffer pointers)
Exit:   A=preserved (via REP)
        X=restored (via PLX)
        Y=modified (internal use)
```

**Calls:**
- CODE_0C8910 - Update PPU registers

**Called By:**
- Main game loop (every frame)
- VBLANK handler (synchronization point)
- Field update routine
- Battle display routine
- Menu rendering system

**Related:**
- See `Display_SpriteOAMDataCopy` @ $0C:$8767 - Bulk OAM copy
- See `docs/GRAPHICS_SYSTEM.md` - Sprite architecture
- See DATA8_0C8659 - Animation frame table

---

### DMA Transfer Operations

#### Graphics_TransferBattleMode
**Location:** Bank $00 @ Section 2 (exact address TBD)  
**File:** `src/asm/bank_00_section2.asm`

**Purpose:** Upload battle graphics to VRAM using DMA during battle transitions - transfers character tiles and tilemap data for battle screen rendering.

**Inputs:**
- Source data at $7F0480 (character graphics, 640 bytes)
- Source data at $7E2040 (tilemap data, 2816 bytes)

**Outputs:**
- VRAM $4400: Character tile data (640 bytes)
- VRAM $5820: Tilemap data (2816 bytes)
- `$00D2` bit 6 set (graphics updated flag)
- OAM data transferred

**Technical Details:**
- **DMA Channel:** Channel 5 ($43xx registers)
- **Transfer Mode:** Word write ($1801 = 2-byte sequential)
- **VRAM Access:** Auto-increment after $2119 write
- **Total Transfer:** 3,456 bytes (640 + 2816)

**Process Flow:**
```
1. Setup VRAM address:
   - Set VRAM write address to $4400
   - VMADDL = $4400 (character data destination)

2. Configure DMA Channel 5:
   - Mode $1801: Word write, increment source
   - Destination: $2118/$2119 (VMDATAL/VMDATAH)
   - Auto-increment enabled

3. Transfer character graphics:
   - Source: $7F0480 (WRAM bank $7F)
   - Size: $0280 bytes (640 bytes = 20 tiles × 32 bytes)
   - Execute DMA transfer (write $20 to $420B)
   - ~640 CPU cycles (DMA overhead)

4. Transfer tilemap data:
   - Set VRAM address to $5820
   - Source: $7E2040 (WRAM bank $7E)
   - Size: $0B00 bytes (2816 bytes)
   - Execute DMA transfer
   - ~2816 CPU cycles (DMA overhead)

5. Update status flags:
   - Set bit 6 of $00D2 (graphics ready)
   - Call CODE_008543 (OAM transfer)
   - Return via RTL
```

**DMA Register Configuration:**
```
DMA Channel 5 Registers ($4350-$4357):
  $4350 (DMAP5):   $01 = 2-byte write mode
  $4351 (BBAD5):   $18 = VRAM data port
  $4352-$4353 (A1T5L/H): Source address (low/high)
  $4354 (A1B5):    Source bank ($7E or $7F)
  $4355-$4356 (DAS5L/H): Transfer size in bytes
  
Trigger:
  $420B (MDMAEN):  $20 = Enable channel 5
```

**Character Tile Layout:**
```
VRAM $4400 (20 tiles, 4bpp format):
  Each tile: 32 bytes (8×8 pixels, 4 bits per pixel)
  Total: 640 bytes = 20 tiles
  
  Tile arrangement:
    $4400-$441F: Tile 0 (32 bytes)
    $4420-$443F: Tile 1
    ...
    $45E0-$45FF: Tile 19
    
  Used for: Battle UI elements, character sprites
```

**Tilemap Layout:**
```
VRAM $5820 (2816 bytes = 1408 words):
  Format: 16-bit tilemap entries
  Each entry: [vhopppcc cccccccc]
    v = vertical flip
    h = horizontal flip
    o = priority
    ppp = palette (0-7)
    cccccccccc = tile number (0-1023)
    
  Dimensions: ~44×32 tiles (screen layout)
  Used for: Battle background, UI windows
```

**Performance Analysis:**
```
DMA Transfer Time (8-bit bus):
  Character data: 640 bytes × ~1 cycle = ~640 cycles
  Tilemap data:   2816 bytes × ~1 cycle = ~2816 cycles
  Setup overhead: ~100 cycles (register writes)
  Total:          ~3,556 cycles
  
  Percentage of frame: 3,556 / 178,000 ≈ 2.0% (NTSC)
  
  Compared to CPU copy (LDA/STA):
    CPU: ~3,456 × 8 = ~27,648 cycles (14× slower)
    DMA wins by factor of ~8 (SNES DMA efficiency)
```

**Side Effects:**
- Writes to VRAM $4400-$467F (640 bytes)
- Writes to VRAM $5820-$631F (2816 bytes)
- Modifies $00D2 (status flags)
- Triggers DMA (halts CPU for ~3,556 cycles)
- Calls CODE_008543 (OAM transfer subroutine)
- Changes VRAM address pointer ($2116/$2117)

**Register Usage:**
```
Entry:  Any state
Work:   A=8-bit (DMA config, banks)
        X=16-bit (addresses, sizes)
Exit:   Undefined (not preserved)
```

**Calls:**
- CODE_008543 - OAM data transfer

**Called By:**
- Battle initialization routine
- Graphics_UpdateFieldMode (conditional branch)
- Screen transition handler

**Related:**
- See `Graphics_UpdateFieldMode` - Field graphics update
- See `docs/GRAPHICS_SYSTEM.md` - VRAM layout
- See DMA technical details in SNES documentation

---

### Graphics Loading

#### Graphics_UpdateFieldMode
**Location:** Bank $00 @ Section 2 (exact address TBD)  
**File:** `src/asm/bank_00_section2.asm`

**Purpose:** Update field/map graphics during gameplay with conditional DMA transfers based on game state flags.

**Inputs:**
- `$00DA` bit 4 = Battle mode flag
- `$00D6` bit 7 = Tilemap update flag
- `$00D6` bit 5 = Display update flag
- `$0042` = Current VRAM base address (16-bit)
- Source data at $7F0040, $7F1040 (character tiles)
- Source data at $7E2040 (tilemap, if flag set)

**Outputs:**
- VRAM at $0042: First tile section (1984 bytes)
- VRAM at $0042+$1000: Second tile section (1984 bytes)
- VRAM $5820: Tilemap (4032 bytes, conditional)
- `$00D4` bits 3-6 set (conditional display update)
- OAM data transferred

**Technical Details:**
- **DMA Channel:** Channel 5
- **Transfer Mode:** Word write ($1801)
- **VRAM Increment:** Vertical mode ($80 to VMAINC)
- **Conditional Paths:** Battle/field mode branching

**Process Flow:**
```
1. Setup VRAM increment mode:
   - Write $80 to VMAINC
   - Increments after $2119 write (VMDATAH)

2. Check battle mode flag:
   - Test $00DA bit 4
   - If set → Branch to Graphics_TransferBattleMode
   - Else → Continue with field graphics

3. Transfer first tile section:
   - VRAM address from $0042 variable
   - Source: $7F0040
   - Size: $07C0 bytes (1984 bytes)
   - DMA channel 5 transfer

4. Calculate second section address:
   - REP #$30 (16-bit mode)
   - Add $1000 to VRAM address
   - Set new VRAM destination

5. Transfer second tile section:
   - Source: $7F1040
   - Size: $07C0 bytes (1984 bytes)
   - DMA channel 5 transfer

6. Check tilemap update flag ($00D6 bit 7):
   - If clear → Skip to OAM transfer
   - If set → Transfer tilemap data
     * VRAM $5820
     * Source: $7E2040
     * Size: $0FC0 bytes (4032 bytes)
     * DMA channel 5 transfer
     * RTL immediately after

7. Fallback path (no tilemap):
   - Call CODE_008543 (OAM transfer)
   - Check $00D6 bit 5
   - If set → Set $00D4 bits 3-6 ($78 TSB)
   - RTL
```

**Tile Section Layout:**
```
Variable VRAM address at $0042:
  Section 1: $0042 + $0000
    Source: $7F0040
    Size: 1984 bytes (62 tiles × 32 bytes)
    
  Section 2: $0042 + $1000
    Source: $7F1040
    Size: 1984 bytes (62 tiles × 32 bytes)
    
  Total: 3968 bytes = 124 tiles (4bpp)
  
  Used for: Field character tiles, map tiles
```

**Conditional Tilemap Transfer:**
```
If $00D6 bit 7 set:
  VRAM $5820: Tilemap data
  Source: $7E2040
  Size: 4032 bytes (2016 words)
  
  Tilemap dimensions: ~63×32 entries
  Format: 16-bit tile index + attributes
  
  Used for: Map layout changes, screen scrolling
```

**Performance Analysis:**
```
Minimum path (no tilemap):
  Section 1: 1984 bytes × ~1 cycle = ~1984 cycles
  Section 2: 1984 bytes × ~1 cycle = ~1984 cycles
  Overhead:  ~150 cycles
  Total:     ~4,118 cycles (~2.3% of frame, NTSC)

Maximum path (with tilemap):
  Sections:  ~3,968 cycles (tiles)
  Tilemap:   4032 bytes × ~1 cycle = ~4032 cycles
  Overhead:  ~200 cycles
  Total:     ~8,200 cycles (~4.6% of frame, NTSC)
  
Battle mode branch:
  Redirects to Graphics_TransferBattleMode
  ~3,556 cycles (see separate function)
```

**Flag Logic:**
```
$00DA bit 4 (Battle mode):
  0 = Field graphics (this function continues)
  1 = Battle graphics (branch to battle transfer)

$00D6 bit 7 (Tilemap update):
  0 = Skip tilemap transfer, call OAM transfer
  1 = Transfer tilemap, RTL immediately

$00D6 bit 5 (Display update):
  0 = Normal exit (RTL)
  1 = Set $00D4 bits 3-6, then RTL

Result determination:
  Battle mode → Always branch out
  Field + tilemap → Transfer 8200 cycles, early exit
  Field + no tilemap → Transfer 4118 cycles, OAM call
```

**Side Effects:**
- Writes to VRAM at variable address ($0042)
- Writes to VRAM at variable address +$1000
- Writes to VRAM $5820 (conditional, 4032 bytes)
- Modifies $00D4 (conditional flag set)
- Triggers DMA (halts CPU, variable duration)
- Calls CODE_008543 (conditional OAM transfer)
- Changes VRAM address pointer ($2116/$2117)
- Changes VMAINC mode ($2115)

**Register Usage:**
```
Entry:  Any state
Work:   A=8-bit (flags, DMA config)
        X=16-bit (addresses, sizes)
Exit:   Undefined (not preserved)
```

**Calls:**
- Graphics_TransferBattleMode (conditional branch)
- CODE_008543 - OAM transfer (conditional)

**Called By:**
- Main game loop (field mode)
- Map scroll handler
- Screen transition manager

**Related:**
- See `Graphics_TransferBattleMode` - Battle graphics
- See `docs/GRAPHICS_SYSTEM.md` - VRAM organization
- See `docs/MAP_SYSTEM.md` - Field rendering

---

### Mode 7 Graphics & Rotation

#### Display_Mode7TilemapSetup
**Location:** Bank $0C @ $87ED  
**File:** `src/asm/bank_0C_documented.asm`

**Purpose:** Initialize Mode 7 tilemap with block fill pattern and setup HDMA for perspective effects.

**Inputs:**
- None (uses hardcoded configuration)

**Outputs:**
- VRAM $4000+ filled with tilemap pattern
- HDMA channels 1 & 2 configured for Mode 7 scrolling
- $0111 = $06 (HDMA enable flags)

**Side Effects:**
- Fills 30 rows × 128 columns in VRAM ($4000+)
- Writes 10 bytes to $7F0000-$7F0009 (HDMA table header)
- Modifies $4204-$4206 (multiply/divide registers)
- Configures $4310-$4317 (DMA channel 1)
- Configures $4320-$4327 (DMA channel 2)
- Modifies data bank register

**Algorithm:**

**Phase 1: Tilemap Fill (30 rows × 128 columns)**
```
1. Set data bank = $0C
2. Call CODE_009994 with:
   - VRAM start: $4000
   - Row count: 30 ($1E)
   - Fill pattern: $C0
3. Pattern fills each row with value $C0
4. Result: 3,840 tiles ($1E × $80 = $0F00)
```

**Phase 2: Mode 7 Calculation Table Setup**
```
For Y = $82 to $E7 (102 values, Y coordinate range):
  1. A = Y × 2 → $4205 (multiply register)
  2. Call CODE_009726 (hardware multiply routine)
  3. Read quotient from $4214 (divide result)
  4. Store to $7F0010+offset (Mode 7 calculation buffer)
  5. Increment X offset by 2 (word table)
  6. Increment Y
  
Result: 102 words at $7F0010-$7F00D9
Purpose: Perspective scaling lookup table
```

**Phase 3: HDMA Channel Configuration**
```
Transfer HDMA table header:
- Source: Bank $0C @ $886B (10 bytes)
- Destination: $7F0000-$7F0009
- Data: [Header][Control bytes]

Configure HDMA Channel 1 (Horizontal scroll):
- $4310 = $42 (Transfer mode: 2 bytes)
- $4311 = $1B (Destination: $211B = M7HOFS)
- $4312 = $0000 (Source address: $7F0000)
- $4314 = $7F (Source bank)
- $4317 = $7F (Indirect bank)

Configure HDMA Channel 2 (Vertical scroll):
- $4320 = $42 (Transfer mode: 2 bytes)
- $4321 = $1E (Destination: $211E = M7VOFS)
- $4322 = $0000 (Source address: $7F0000)
- $4324 = $7F (Source bank)
- $4327 = $7F (Indirect bank)

Enable channels:
- $0111 = $06 (Enable channels 1 & 2)
```

**HDMA Table Format (DATA8_0C886B):**
```
Offset  Value   Meaning
+$00    $FF     Scanline count (255 lines)
+$01    $10     Scroll low byte
+$02    $00     Scroll high byte
+$03    $D1     Scanline count (209 lines)
+$04    $0E     Scroll low byte
+$05    $01     Scroll high byte
+$06    $00     End marker

Effect: First 255 lines → scroll $0010
        Next 209 lines → scroll $01D1
        Creates perspective depth illusion
```

**Performance:**
```
Tilemap fill:   ~3,840 tiles × 2 bytes = 7,680 bytes
Calculation:    102 multiply operations
HDMA setup:     10-byte block move + register writes
Total time:     ~50,000 cycles (~2.8ms @ 1.79 MHz)
Per-frame cost: 0 (HDMA runs automatically during scanout)
```

**Mode 7 HDMA Perspective Effect:**
```
This creates the classic SNES "pseudo-3D" effect:
- Each scanline gets different scroll offset
- Top of screen: Small offset → far distance
- Bottom of screen: Large offset → near distance
- Updates automatically via HDMA (no CPU cost per frame)
- Used for world map rotation, race tracks, flying scenes
```

**Register Usage:**
```
Entry:  Any state
Work:   A=8-bit (values, loop control)
        X=16-bit (addresses, counters)
        Y=16-bit (loop counter, row index)
        DB=varies ($0C → $7F)
Exit:   A=8-bit (accumulator size preserved)
        DB=$0C (restored)
```

**Calls:**
- CODE_009994 - Tilemap fill routine
- CODE_009726 - Hardware multiply routine

**Called By:**
- World map initialization
- Mode 7 screen setup
- Title screen rotation setup
- Flying sequence initialization

**Related:**
- Display_Mode7MatrixInit - Sets transformation matrix
- Display_Mode7RotationSequence - Animated rotation
- See SNES Dev Manual - Mode 7 Background Mode

---

#### Display_Mode7MatrixInit
**Location:** Bank $0C @ $88BE  
**File:** `src/asm/bank_0C_documented.asm`

**Purpose:** Initialize Mode 7 affine transformation matrix to identity (no rotation/scale) and set center point.

**Inputs:**
- None (uses hardcoded configuration)

**Outputs:**
- Mode 7 matrix = Identity (no transform)
- M7X/M7Y center = ($0118, $0084) = (280, 132)
- BG1 scroll = (4, -8)
- $2115 (VMAINC) = 0 (increment by 1)

**Side Effects:**
- Modifies $211B-$211E (Mode 7 matrix registers)
- Modifies $211F-$2120 (Mode 7 center point)
- Modifies $210D-$210E (BG1 scroll)
- Modifies $2115 (VRAM increment mode)
- Modifies data bank register
- Returns A = $11 (base tile pattern)

**Algorithm:**

**Phase 1: Setup & VBLANK Wait**
```
1. Set data bank = $0C
2. CLC (prepare for calculations)
3. A = $84 (center Y coordinate)
4. Wait for VBLANK (jsl CODE_0C8000)
5. Set VMAINC = 0 (VRAM increment by 1 word)
```

**Phase 2: Mode 7 Center Point**
```
M7X (horizontal center):
- $211F (M7X low) = $00
- $211F (M7X high) = $00
- Result: M7X = $0000 (but note write sequence)

M7Y (vertical center):
- $2120 (M7Y low) = $18
- $2120 (M7Y high) = $01
- Result: M7Y = $0118 (280 pixels)

Note: Registers written twice for 16-bit value
      First write = low byte, second = high byte
```

**Phase 3: Identity Matrix Setup**
```
Set transformation matrix to identity:
┌         ┐
│ 1   0   │  =  ┌               ┐
│ 0   1   │     │ $0100  $0000  │
└         ┘     │ $0000  $0100  │
                └               ┘

M7A (A parameter): Not set (assumes $0100 from caller)
M7B (B parameter): $0000
M7C (C parameter): $0000
M7D (D parameter): Not set (assumes $0100 from caller)

Register writes:
- $211C (M7B) low  = $00
- $211C (M7B) high = $00 → M7B = $0000
- $211D (M7C) low  = $00
- $211D (M7C) high = $00 → M7C = $0000

Identity matrix effect:
- No rotation (angle = 0°)
- No scaling (scale = 1.0)
- Direct 1:1 pixel mapping
```

**Phase 4: Initial Scroll Offset**
```
BG1 Horizontal Offset:
- $210D (BG1HOFS) low  = $04 (4 pixels right)
- $210D (BG1HOFS) high = $00
- Result: H-scroll = +4 pixels

BG1 Vertical Offset:
- $210E (BG1VOFS) low  = $F8 (-8 pixels up)
- $210E (BG1VOFS) high = $00
- Result: V-scroll = -8 pixels (negative wrap)

Effect: Slight offset from origin
        H=+4 shifts view right 4 pixels
        V=-8 shifts view up 8 pixels
```

**Phase 5: Return Base Tile**
```
A = $11 (base tile pattern number)
Return to caller
```

**Mode 7 Matrix Mathematics:**
```
Identity matrix formula:
[ X' ]   [ 1  0 ] [ X - Xc ]   [ Xc ]
[ Y' ] = [ 0  1 ] [ Y - Yc ] + [ Yc ]

Simplifies to:
X' = X (no change)
Y' = Y (no change)

For rotation by angle θ:
[ X' ]   [ cos(θ)  -sin(θ) ] [ X - Xc ]   [ Xc ]
[ Y' ] = [ sin(θ)   cos(θ) ] [ Y - Yc ] + [ Yc ]

SNES register mapping:
M7A = A parameter (cos θ in $00-$FF format)
M7B = B parameter (-sin θ)
M7C = C parameter (sin θ)
M7D = D parameter (cos θ)
M7X = Center X (280 pixels)
M7Y = Center Y (132 pixels)
```

**Center Point Calculation:**
```
X center = $0118 = 280 pixels
Y center = $0084 = 132 pixels

Screen size: 256×224 (NTSC) or 256×239 (PAL)
Center offset: Slightly right of screen center
               280 - 128 = 152 pixels right
               132 - 112 = 20 pixels down

Purpose: Centers rotation around specific map point
         Not screen center, but game world center
```

**Performance:**
```
VBLANK wait:    Variable (~16,700 cycles typical)
Register writes: ~80 cycles (8 writes × ~10 cycles)
Total:          ~16,780 cycles (~0.9ms)
Critical path:  Must execute during VBLANK
```

**Register Usage:**
```
Entry:  Any state
Work:   A=8-bit (register values)
        DB=$0C
Exit:   A=$11 (base tile pattern)
        DB=$0C (preserved)
```

**Calls:**
- CODE_0C8000 - Wait for VBLANK

**Called By:**
- World map mode initialization
- Battle background setup (Mode 7 battles)
- Title screen initialization
- Flying sequence start

**Related:**
- Display_Mode7TilemapSetup - Tilemap and HDMA setup
- Display_Mode7RotationSequence - Rotation animation
- CODE_0C8A78 - Mode 7 matrix update routine
- See SNES Dev Manual - Mode 7 Registers ($211B-$2120)

**Technical Notes:**
```
Mode 7 Limitations:
- Single background layer only
- No transparency (except color 0)
- 128×128 tile maximum (1024×1024 pixels)
- No horizontal/vertical flip (must use matrix)
- Center point limited to signed 13-bit range

Common Uses in FFMQ:
- World map rotation (airship flight)
- Battle backgrounds (some bosses)
- Title screen effects
- Special cutscenes
```

---

#### Display_Mode7RotationSequence
**Location:** Bank $0C @ $896F  
**File:** `src/asm/bank_0C_documented.asm`

**Purpose:** Perform animated Mode 7 rotation effect with smooth matrix interpolation, sprite positioning, and color fade effects.

**Inputs:**
- Sine/cosine tables at $8B86 and $8B96 (rotation angles)
- $0C00+ sprite buffer (12 sprites)
- Mode 7 matrix must be initialized

**Outputs:**
- Completes full rotation animation sequence
- Updates sprite positions (12 sprites)
- Performs 8-step brightness fade
- Enables NMI OAM transfer
- Disables color math on exit

**Side Effects:**
- Modifies $210E (BG1 vertical scroll)
- Modifies $4202+ (hardware multiply registers)
- Modifies $211B-$211E (Mode 7 matrix)
- Modifies $0062-$0063 (sprite position state)
- Modifies $2130-$2132 (color math registers)
- Modifies $005A/$0058 (NMI handler pointer)
- Modifies $00E2 (NMI control flags)
- Modifies $0505 (effect state flag)
- Modifies $0C04+ (sprite brightness values)
- Updates OAM via DMA (544 bytes)

**Algorithm:**

**Phase 1: Initial Setup**
```
1. BG1 vertical scroll = $D4 (-44 pixels)
   - Low byte:  $D4 → $210E
   - High byte: $FF → $210E (sign extend negative)
   
2. Load table pointers:
   - X = $8B86 (sine/cosine table 1)
   - Y = $8B96 (rotation angle table)
```

**Phase 2: Main Rotation Loop**
```
For each rotation angle in table at $8B96:
  1. Load angle from table: A = [$0000,Y]
  2. If angle = 0: Exit to post-rotation fade
  3. Save table pointer (PHY)
  4. Wait for VBLANK (jsl CODE_0C8000)
  5. Update Mode 7 matrix (jsr CODE_0C8A78):
     - Reads sine/cosine from table
     - Writes to $211B-$211E (M7A-M7D)
     - Uses $4202 hardware multiply
  6. Restore table pointer (PLY)
  
  7. Calculate dynamic vertical scroll:
     - A = Y - $AB (table offset to pixel offset)
     - A = A × 2 (multiply by 2)
     - Write to $210E (BG1VOFS low)
     - If A = 0: High byte = $00
     - If A ≠ 0: High byte = $FF (negative scroll)
  
  8. Increment Y (next angle)
  9. Loop back to step 1

Effect: Smooth rotation over ~20-40 frames
        Scroll adjusts to keep content centered
        Frame-synchronized via VBLANK
```

**Phase 3: Post-Rotation Fade (30 frames)**
```
Loop counter = 30 frames:
  1. Wait for VBLANK
  2. Update Mode 7 matrix (jsr CODE_0C8A76)
  3. Decrement counter
  4. Repeat 30 times

Purpose: Hold final rotation state
         Smooth transition before sprite animation
```

**Phase 4: Sprite Position Animation**
```
Initialize:
- $0062 = $0101 (X/Y start position)

Main sprite loop (until X=$0C):
  1. Load position: Y = $0062
  2. Update sprite coordinates (jsr CODE_0C8A3F)
  3. Increment X: $0062++
  4. Increment Y: $0063++
  
  5. Repeat update (staggered):
     - Second sprite update with incremented position
     - $0062++ and $0063++ again
  
  6. Check if X = $0C:
     - If yes: Branch to table sync wait
     - If no: Third sprite update, continue loop

Pattern: 3 sprite updates per iteration
         X increments: $01 → $02 → $03 ... → $0C
         Y increments in parallel
         Creates diagonal motion from ($01,$01) to ($0C,?)
```

**Phase 5: Table Synchronization Wait**
```
Loop until table index = $8B66:
  1. Wait for VBLANK
  2. Update Mode 7 matrix (jsr CODE_0C8A76)
  3. Check X register: X = $8B66?
  4. Loop if not synced

Then hold stable for additional frames:
  (Same loop, ensures stable state before fade)

Purpose: Synchronize rotation table wrap-around
         Ensure smooth transition to fade sequence
```

**Phase 6: Color Math Setup**
```
Setup NMI OAM transfer:
- Call Display_SetupNMIOAMTransfer
- $005A = $0C (NMI handler bank)
- $0058 = $8929 (NMI handler address)
- $00E2 |= $40 (enable OAM transfer flag)

Color math configuration:
- $0505 = $30 (effect state flag)
- $2130/$2131 = $2100 (color window mode)
- $2132 = $FF (fixed color: maximum brightness white)
```

**Phase 7: Brightness Fade-In (8 steps)**
```
For brightness level = 8 down to 1:
  1. Save brightness level (PHA)
  2. Load sprite count: Y = $000C (12 sprites)
  3. Load buffer pointer: X = $0C04
  
  4. Per-sprite brightness loop (12 sprites):
     - Decrement brightness: [$0000,X]--
     - Advance pointer: X += 4 (sprite structure size)
     - Decrement counter: Y--
     - Repeat for all 12 sprites
  
  5. Setup NMI OAM transfer (updates sprite buffer)
  6. Wait for VBLANK (makes changes visible)
  
  7. Calculate color math value:
     - Load brightness from stack (without popping)
     - Decrement: brightness--
     - Multiply by 4: brightness × 4
     - OR with $E0: brightness | $E0 (red channel mask)
     - Write to $2132 (COLDATA - fixed color add/sub)
  
  8. Restore brightness (PLA)
  9. Decrement loop counter
  10. Repeat for all 8 levels

Brightness progression:
Level 8: Color=$E0+(7×4)=$FC (very bright)
Level 7: Color=$E0+(6×4)=$F8
Level 6: Color=$E0+(5×4)=$F4
...
Level 1: Color=$E0+(0×4)=$E0 (base level)

Effect: 8-frame fade from bright to normal
        Affects all on-screen graphics via color math
        Synchronized with sprite brightness decrease
```

**Phase 8: Cleanup**
```
Disable color math:
- $2131 (CGADSUB) = $00 (no color add/subtract)

Return to caller
```

**Rotation Table Format:**
```
Table at $8B96: Sequence of angle values
- Values represent rotation angle (0-255 = 0-360°)
- Value $00 = end marker (exit rotation loop)
- Typical sequence: gradual angle progression
  Example: $10, $20, $30, ..., $F0, $00

Sine/Cosine tables at $8B86:
- Pre-calculated trigonometry values
- Format: 256-entry tables (one full rotation)
- Used by CODE_0C8A78 to calculate matrix
```

**Sprite Structure (12 sprites at $0C04+):**
```
Each sprite: 4 bytes
Offset +0: X coordinate
Offset +1: Y coordinate (brightness modified here)
Offset +2: Tile number
Offset +3: Attributes (palette, priority, flip)

Total size: 12 sprites × 4 bytes = 48 bytes
Modified: Only offset +1 during fade (brightness)
```

**Performance:**
```
Phase 2 (rotation): ~20-40 frames × ~20,000 cycles/frame
Phase 3 (fade):     30 frames × ~20,000 cycles/frame
Phase 4 (sprites):  Variable (~10-20 frames)
Phase 5 (sync):     Variable (~5-10 frames)
Phase 7 (bright):   8 frames × ~25,000 cycles/frame

Total duration: ~60-100 frames (~1.0-1.7 seconds @ 60 FPS)
Per-frame cost: ~20,000-25,000 cycles (11-14% CPU)
```

**Color Math Effect:**
```
COLDATA register ($2132) format:
Bit 7-6: Unused
Bit 5:   Blue channel enable ($20)
Bit 4:   Green channel enable ($10)
Bit 3:   Red channel enable ($08)
Bit 2-0: Color intensity (0-31)

Value $E0 = %11100000:
- Red enabled ($20)
- Green enabled ($40)
- Blue enabled ($80)
- Intensity = 0 (from lower bits)

During fade:
- Intensity increases: 0 → 28 (7×4)
- Creates white fade effect
- Affects all BG layers and sprites (if enabled)
```

**Register Usage:**
```
Entry:  A=any, X=any, Y=any
Work:   A=8/16-bit (varies, multi-purpose)
        X=16-bit (table pointers, buffer addresses)
        Y=16-bit (table pointers, loop counters)
        DB=$0C (set by function)
Exit:   A=undefined
        X=undefined
        Y=undefined
        DB=$0C
```

**Calls:**
- CODE_0C8000 - Wait for VBLANK
- CODE_0C8A78 - Update Mode 7 matrix with multiply
- CODE_0C8A76 - Update Mode 7 matrix (alternate)
- CODE_0C8A3F - Calculate sprite screen position
- Display_SetupNMIOAMTransfer - Enable NMI OAM DMA

**Called By:**
- Title screen rotation sequence
- World map entrance (airship takeoff)
- Battle intro effects (Mode 7 backgrounds)
- Special cutscenes (dramatic reveals)

**Related:**
- Display_Mode7TilemapSetup - Initialize tilemap and HDMA
- Display_Mode7MatrixInit - Set identity matrix
- Display_SetupNMIOAMTransfer - OAM DMA configuration
- See SNES Dev Manual - Mode 7 rotation/scaling
- See SNES Dev Manual - Color math ($2130-$2132)

**Technical Notes:**
```
Rotation Smoothness:
- Frame-synchronized updates (60 FPS)
- Hardware multiply for fast matrix calculation
- Pre-calculated sine/cosine tables (no runtime trig)
- Typical rotation: ~1-2 seconds full sequence

Sprite Fade Integration:
- Brightness values directly modify OAM data
- 8-step fade matches color math fade
- NMI transfer ensures tear-free updates
- Synchronized with VBLANK for smooth effect

Performance Optimization:
- Hardware multiply ($4202) instead of software
- Pre-calculated trig tables (ROM lookup)
- DMA for OAM transfer (much faster than CPU)
- HDMA for scroll (no CPU cost per scanline)

Common Issues:
- Table pointer wrap-around (sync wait required)
- Color math must be disabled after fade
- NMI handler must be set before sprite updates
- VBLANK timing critical (skipped frames = jerky rotation)
```

---

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

#### RNG_GenerateRandom
**Location:** Bank $00 @ $9783  
**File:** `src/asm/banks/bank_00.asm`

**Purpose:** Generate pseudo-random number with optional modulo operation for bounded ranges.

**Inputs:**
- `$A8` (Direct Page $4A) = Modulo divisor (0 = no modulo, returns full 8-bit)
- `$701FFE` = RNG seed (3 bytes in WRAM)
- `$0E96` = Frame counter (entropy source)

**Outputs:**
- `A` (Direct Page $4B at $A9) = Random number (0 to modulo-1, or 0-255 if no modulo)
- `$701FFE` = Updated RNG seed

**Technical Details:**
- Uses Linear Congruential Generator (LCG) algorithm
- Formula: `seed = (seed × 5 + seed × 1 + $3711 + frame_counter)`
- Utilizes hardware division for modulo operation ($4204-$4216)
- Preserves processor state (PHP/PLP, PHD/PLD)

**Process Flow:**
```asm
1. Save state:
   PHP                       ; Save processor status
   PHD                       ; Save direct page
   REP #$30                  ; 16-bit mode
   PHA                       ; Save A

2. Set direct page:
   LDA #$005E
   TCD                       ; Set DP to $005E

3. Load and update seed:
   LDA $701FFE               ; Load 16-bit seed from WRAM
   ASL A                     ; seed × 2
   ASL A                     ; seed × 4
   ADC $701FFE               ; seed × 4 + seed = seed × 5
   ADC #$3711                ; Add constant
   ADC $0E96                 ; Add frame counter (entropy)
   STA $701FFE               ; Store new seed

4. Extract random byte:
   SEP #$20                  ; 8-bit A
   XBA                       ; Swap bytes (get high byte)
   STA $4B                   ; Store to result ($00A9)
   STA SNES_WRDIVL ($4204)   ; Setup for division
   STZ SNES_WRDIVH ($4205)   ; High byte = 0

5. Apply modulo (if requested):
   LDA $4A                   ; Load modulo value
   BEQ ModuloFinish          ; If 0, skip modulo
   JSL Math_SetDivisor       ; Set $4206 divisor
   LDA SNES_RDMPYL ($4216)   ; Read remainder
   STA $4B                   ; Store modulo result

6. Restore and return:
ModuloFinish:
   REP #$30                  ; 16-bit mode
   PLA                       ; Restore A
   PLD                       ; Restore DP
   PLP                       ; Restore status
   RTL
```

**RNG Algorithm Details:**
```
Seed Update Formula:
  new_seed = (old_seed × 5) + $3711 + frame_counter
  
Multiplication breakdown:
  seed × 5 = (seed << 2) + seed
  
Components:
  ASL A (×2)
  ASL A (×4)
  ADC original (×4 + ×1 = ×5)
  
Entropy sources:
  $3711: Magic constant for period
  $0E96: Frame counter (changes every frame)
  
Period: ~65,536 before repeat (16-bit seed)
```

**Modulo Operation:**
```
Hardware division registers (SNES math unit):
  $4204-4205 (WRDIVL/H): 16-bit dividend
  $4206 (WRDIVB): 8-bit divisor
  $4214-4215 (RDDIVL/H): 16-bit quotient
  $4216-4217 (RDMPYL/H): 16-bit remainder

For modulo N:
  Input: random_byte (0-255)
  Divisor: N
  Result: remainder (0 to N-1)
  
Example for dice roll (1-6):
  Set $4A = 6
  Result = (random_byte % 6) → 0-5
  Add 1 in caller → 1-6
```

**Direct Page Usage:**
```
Set DP to $005E for access to:
  $A8 ($4A): Modulo input
  $A9 ($4B): Random output
  
DP offset calculation:
  Actual address = DP + offset
  $005E + $4A = $00A8
  $005E + $4B = $00A9
```

**Seed Storage ($701FFE):**
```
Location: WRAM Bank $70, offset $1FFE
Size: 3 bytes (24-bit for better period)
Access: Long addressing (LDA.L)
Initialized: At game boot with timer value
Persistent: Across battles/menus
```

**Use Cases:**
```
Battle variance:
  RNG_GenerateRandom with modulo = damage_range
  Apply to base damage

Item drops:
  RNG_GenerateRandom with modulo = 100
  Compare to drop_rate percentage

Enemy AI:
  RNG_GenerateRandom with modulo = action_count
  Select AI action

Treasure chests:
  RNG_GenerateRandom with modulo = item_pool_size
  Select reward item
```

**Side Effects:**
- Modifies `$701FFE` (RNG seed - 16-bit)
- Modifies `$00A9` ($4B) (random result)
- Uses `$4204-$4206` (division registers)
- Reads `$0E96` (frame counter)
- Temporarily changes direct page to $005E

**Calls:**
- `Math_SetDivisor` @ $009726 (JSL) - Set hardware divisor

**Called By:**
- Battle damage calculation
- Enemy AI decision making
- Item drop determination
- Random encounters
- Treasure generation
- Variance calculations

**Related:**
- See `Random` @ $8456 for simpler 8-bit RNG
- See hardware math unit documentation for division
- See entropy sources for randomness quality

---

### Frame Synchronization

### Memory Management

#### Memory_Copy64Bytes
**Location:** Bank $00 @ $A216 (approximately)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Fast block memory copy for exactly 64 bytes - unrolled loop for maximum speed.

**Inputs:**
- `X` (16-bit) = Source address offset
- `Y` (16-bit) = Destination address offset
- Processor mode: REP #$30 (16-bit A, X, Y assumed)

**Outputs:**
- 64 bytes copied from source to destination
- Falls through to Memory_Copy32Bytes to complete remaining 32 bytes

**Technical Details:**
- Unrolled loop (no branching overhead)
- Copies 16-bit words (32 word transfers = 64 bytes)
- Falls through to copy additional 32 bytes (total 96 bytes capability)
- Optimized for speed over code size
- Used for OAM buffer copies, sprite data transfers

**Process Flow:**
```asm
Copy words at offsets (descending):
  $3E/$3C (bytes 62-63, 60-61)
  $3A/$38 (bytes 58-59, 56-57)
  $36/$34 (bytes 54-55, 52-53)
  $32/$30 (bytes 50-51, 48-49)
  $2E/$2C (bytes 46-47, 44-45)
  $2A/$28 (bytes 42-43, 40-41)
  $26/$24 (bytes 38-39, 36-37)
  $22/$20 (bytes 34-35, 32-33)

Fall through to Memory_Copy32Bytes:
  $1E-$00 (bytes 30-31 down to 0-1)
```

**Copy Pattern:**
```
For each word (2 bytes):
  LDA $xxxx,X    ; Load word from source + offset
  STA $xxxx,Y    ; Store word to dest + offset
  
16 word copies:
  64 bytes total transferred
  
Fall-through design:
  No RTS after $20 copy
  Continues to Memory_Copy32Bytes
  Total capability: 96 bytes (64 + 32)
```

**Performance Characteristics:**
```
Unrolled loop benefits:
  - No branch overhead
  - No loop counter decrement
  - No conditional checks
  - Fixed 64-byte size

Cycle count (approximate):
  LDA abs,X: 4-5 cycles
  STA abs,Y: 5 cycles
  Per word: ~9-10 cycles
  
  16 words × 10 = ~160 cycles for 64 bytes
  Plus 32-byte fall-through = ~80 cycles
  
  Total: ~240 cycles for 96 bytes
  (~2.5 cycles per byte - very fast!)
```

**Common Use Cases:**
```
OAM buffer copy (128 sprites × 4 bytes = 512 bytes):
  Multiple 64-byte calls
  Fast sprite table updates
  
Tilemap buffer:
  Copy 64-byte screen rows
  VRAM preparation
  
Entity data:
  Copy character stats (64 bytes)
  Copy enemy data structures
  
Graphics buffer:
  Sprite frame data
  Pattern table blocks
```

**Memory Layout Example:**
```
Source buffer (Bank $7E):
  X = $3000 (base address)
  
  $303E-$303F: Bytes 62-63
  $303C-$303D: Bytes 60-61
  ...
  $3000-$3001: Bytes 0-1

Destination buffer (Bank $7E):
  Y = $4000 (base address)
  
  $403E-$403F: Bytes 62-63 (copied)
  $403C-$403D: Bytes 60-61 (copied)
  ...
  $4000-$4001: Bytes 0-1 (copied)
```

**Comparison to MVN Instruction:**
```
MVN (Block Move Negative):
  Flexible size (any byte count)
  Slower setup (3-byte instruction)
  ~7 cycles per byte
  Better for variable sizes

Memory_Copy64Bytes:
  Fixed 64-byte size
  No setup overhead
  ~2.5 cycles per byte
  Better for fixed sizes

Use unrolled when:
  - Size is always 64 bytes
  - Speed is critical
  - Code size not a concern
```

**Side Effects:**
- Modifies 64 bytes at destination address
- Clobbers A register (final value = last word copied)
- Falls through to Memory_Copy32Bytes (copies 32 more bytes)
- X, Y preserved (not modified)

**Calls:**
- None (falls through to Memory_Copy32Bytes)

**Called By:**
- OAM update routines
- Sprite buffer copying
- Entity data transfers
- Tilemap updates

**Related:**
- See `Memory_Copy32Bytes` for 32-byte variant
- See `Memory_CopyToRAM` for flexible MVN-based copy
- See `Memory_CopyFromRAM` for reverse copy

---

#### Memory_Copy32Bytes
**Location:** Bank $00 @ $A24A (approximately)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Fast block memory copy for exactly 32 bytes - unrolled loop continuation from 64-byte copy.

**Inputs:**
- `X` (16-bit) = Source address offset
- `Y` (16-bit) = Destination address offset
- Processor mode: REP #$30 (16-bit A, X, Y assumed)

**Outputs:**
- 32 bytes copied from source to destination
- Returns to caller (RTS)

**Technical Details:**
- Unrolled loop (16 word transfers = 32 bytes)
- Can be called independently or as fall-through from Memory_Copy64Bytes
- Copies offsets $1E down to $00 (bytes 30-31 to 0-1)
- Returns after completion (RTS)

**Process Flow:**
```asm
Copy words at offsets (descending):
  $1E/$1C (bytes 30-31, 28-29)
  $1A/$18 (bytes 26-27, 24-25)
  $16/$14 (bytes 22-23, 20-21)
  $12/$10 (bytes 18-19, 16-17)
  $0E/$0C (bytes 14-15, 12-13)
  $0A/$08 (bytes 10-11, 8-9)
  $06/$04 (bytes 6-7, 4-5)
  $02/$00 (bytes 2-3, 0-1)

Complete:
  RTS - Return to caller
```

**Copy Pattern:**
```
For each word (2 bytes):
  LDA $xxxx,X    ; Load word from source + offset
  STA $xxxx,Y    ; Store word to dest + offset
  
16 word copies:
  32 bytes total transferred
  
Independent use:
  Can be called directly for 32-byte copies
  
Fall-through use:
  Completes Memory_Copy64Bytes
  Total 96 bytes when combined
```

**Performance:**
```
Cycle count (approximate):
  16 words × ~10 cycles = ~160 cycles
  RTS: 6 cycles
  Total: ~166 cycles for 32 bytes
  (~5.2 cycles per byte)
  
Comparison:
  MVN: ~7 cycles per byte
  Unrolled: ~5.2 cycles per byte
  Speed gain: ~25% faster
```

**Use Cases:**
```
Standalone 32-byte copies:
  - Character name (8 chars × 2 bytes + padding)
  - Palette row (16 colors × 2 bytes)
  - Partial sprite data
  - Small entity structures

Combined with 64-byte copy:
  - Total 96-byte blocks
  - Extended entity data
  - Larger sprite frames
```

**Side Effects:**
- Modifies 32 bytes at destination address
- Clobbers A register
- X, Y preserved
- Returns to caller (RTS)

**Calls:**
- None (leaf function)

**Called By:**
- Memory_Copy64Bytes (fall-through)
- Direct calls for 32-byte transfers
- Entity management
- Buffer operations

**Related:**
- See `Memory_Copy64Bytes` for larger block copy
- See `Memory_CopyToRAM` for MVN-based variable copy

---

#### Memory_CopyToRAM
**Location:** Bank $00 @ $A89B (approximately)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Flexible block memory copy using MVN (Move Negative) instruction - copies from Bank $00 to Bank $7E with pointer tracking.

**Inputs:**
- `[$17]` (indirect) = Destination offset in Bank $7E (16-bit)
- `[$17+2]` (indirect) = Byte count (8-bit)
- `$7E3367` = Current source pointer in Bank $7E (updated continuously)

**Outputs:**
- Data copied from Bank $00 to Bank $7E
- `$7E3367` = Updated source pointer (advanced by byte count)
- `[$17]` pointer advanced by 4 bytes (dest + count consumed)

**Technical Details:**
- Uses MVN instruction for flexible variable-length copies
- Tracks cumulative pointer in $7E3367 (buffer position)
- Overflow protection (checks against $35D9 limit)
- Automatically handles bank switching (Bank $00 ↔ Bank $7E)

**Process Flow:**
```asm
1. Load destination offset:
   LDA [$17]         ; Get dest offset (16-bit)
   INC $17 (×2)      ; Advance pointer
   TAX               ; X = destination offset

2. Load source pointer:
   LDA $7E3367       ; Get current buffer position
   TAY               ; Y = source in Bank $7E

3. Load byte count:
   LDA [$17]         ; Get count (8-bit in 16-bit)
   INC $17           ; Advance pointer
   AND #$00FF        ; Isolate low byte
   DEC A             ; Count-1 for MVN

4. Execute block move:
   PHB               ; Save data bank
   MVN $7E,$00       ; Move Y(Bank$00) → X(Bank$7E), A+1 bytes
   PLB               ; Restore data bank
   
   Note: MVN updates Y (source end position)

5. Check for overflow:
   TYA               ; Transfer end pointer to A
   CMP #$35D9        ; Check against buffer limit
   BCC Update        ; If below, safe to update
   JMP Overflow      ; Else handle overflow

6. Update pointer:
Update:
   STA $7E3367       ; Store new pointer position
   (Continue execution)
```

**MVN Instruction Details:**
```
MVN syntax: MVN dest_bank, src_bank

Operation:
  while (A >= 0):
    [X in dest_bank] = [Y in src_bank]
    X++
    Y++
    A--
  
Inputs:
  A = byte_count - 1
  X = destination address
  Y = source address
  
Outputs:
  A = $FFFF (decremented to -1)
  X = dest + count
  Y = src + count
```

**Buffer Pointer Management:**
```
$7E3367 = Cumulative buffer position

Initial state:
  $7E3367 = $3000 (example start)

After copy 1 (50 bytes):
  $7E3367 = $3032

After copy 2 (30 bytes):
  $7E3367 = $3050

Overflow check:
  If $7E3367 >= $35D9:
    Buffer full! Jump to overflow handler
    Reset pointer or flush buffer
```

**Overflow Handling:**
```
Limit: $35D9 (13785 bytes from base)

When exceeded:
  JMP CODE_009D1F (overflow handler)
  
Overflow handler likely:
  - Flushes buffer to VRAM
  - Resets $7E3367 to base
  - Resumes operation
  
Prevents buffer overrun
```

**Use Cases:**
```
Dynamic graphics loading:
  - Copy sprite data to RAM buffer
  - Queue for VRAM transfer
  - Track position for next copy

Decompression output:
  - Write decompressed data to buffer
  - Auto-advance pointer
  - Check for buffer full

Tilemap assembly:
  - Build screen in RAM
  - Piece-by-piece construction
  - Single VRAM transfer when complete

Text rendering:
  - Layout text in buffer
  - Combine multiple strings
  - Transfer during VBLANK
```

**Comparison to Unrolled Loops:**
```
MVN-based (this function):
  + Flexible size (any byte count)
  + Automatic pointer management
  + Overflow protection
  - Slower (~7 cycles/byte)
  - Setup overhead

Unrolled (64/32-byte):
  + Faster (~2.5-5 cycles/byte)
  + No overflow risk (fixed size)
  - Fixed size only
  - No pointer tracking
  - Larger code size

Use MVN when:
  - Size varies
  - Pointer tracking needed
  - Overflow protection required
```

**Side Effects:**
- Modifies destination buffer in Bank $7E
- Updates `$7E3367` (source pointer)
- Advances `[$17]` pointer by 4 bytes
- Clobbers A, X, Y registers
- May jump to overflow handler (non-return)

**Calls:**
- None (MVN is hardware instruction)
- May call overflow handler @ $9D1F

**Called By:**
- Graphics decompression routines
- Tilemap construction
- Text rendering
- Dynamic buffer management

**Related:**
- See `Memory_CopyFromRAM` for reverse copy (Bank $7E → Bank $00)
- See `Memory_Copy64Bytes` for fixed-size fast copy
- See buffer management documentation

---

#### Memory_CopyFromRAM
**Location:** Bank $00 @ $A8AB (approximately)  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Reverse block memory copy using MVN - copies from Bank $7E back to Bank $00 with automatic pointer adjustment.

**Inputs:**
- `[$17]` (indirect) = Destination address in Bank $00 (16-bit)
- `[$17+2]` (indirect) = Byte count (8-bit)
- `$7E3367` = Current source pointer in Bank $7E (decremented by copy)

**Outputs:**
- Data copied from Bank $7E to Bank $00
- `$7E3367` = Updated source pointer (decreased by byte count)
- `[$17]` pointer advanced by 3 bytes (dest + count consumed)

**Technical Details:**
- Reverse of Memory_CopyToRAM (Bank $7E → Bank $00)
- Decrements buffer pointer instead of incrementing
- Uses MVN for flexible variable-length copies
- No overflow check (reading backwards from buffer)

**Process Flow:**
```asm
1. Load destination:
   LDA [$17]         ; Get dest in Bank $00
   INC $17 (×2)      ; Advance pointer
   TAY               ; Y = destination

2. Load byte count:
   LDA [$17]         ; Get count (8-bit)
   INC $17           ; Advance pointer
   AND #$00FF        ; Isolate low byte
   PHA               ; Save count

3. Adjust source pointer:
   EOR #$FFFF        ; Bitwise NOT (negate)
   ADC $7E3367       ; Subtract count from pointer
   STA $7E3367       ; Update pointer (moved backward)
   TAX               ; X = new source position

4. Execute block move:
   PLA               ; Restore count
   DEC A             ; Count-1 for MVN
   MVN $00,$7E       ; Move X(Bank$7E) → Y(Bank$00)
   
   (No bank save/restore - different flow)
```

**Pointer Arithmetic:**
```
Decrement calculation:
  new_ptr = old_ptr - count

Implementation:
  count_negated = ~count (bitwise NOT)
  new_ptr = old_ptr + count_negated
  
Example:
  old_ptr = $3050
  count = 30 ($1E)
  
  ~count = $FFE1 (two's complement -30)
  new_ptr = $3050 + $FFE1 = $3031
  
  Check: $3050 - 30 = $3031 ✓
```

**Buffer Traversal:**
```
Forward copy (ToRAM):
  $7E3367 starts at $3000
  After 50 bytes: $3032
  After 30 more: $3050
  Pointer grows →

Reverse copy (FromRAM):
  $7E3367 at $3050
  Copy 30 bytes: $3031
  Copy 20 bytes: $301D
  Pointer shrinks ←

Use pattern:
  1. Build buffer forward (ToRAM)
  2. Process/modify in place
  3. Read back backward (FromRAM)
```

**Use Cases:**
```
Buffer readback:
  - Copy processed data back to ROM bank
  - Retrieve decompressed graphics
  - Read back modified tilesets

Double buffering:
  - Write to buffer (ToRAM)
  - Process data
  - Read back results (FromRAM)

Temporary storage:
  - Save state to buffer
  - Modify working data
  - Restore from buffer
```

**MVN Direction:**
```
Forward (ToRAM):
  MVN $7E,$00
  Source: Bank $00 (ROM/fixed data)
  Dest: Bank $7E (RAM buffer)
  Pointer increases

Backward (FromRAM):
  MVN $00,$7E
  Source: Bank $7E (RAM buffer)
  Dest: Bank $00 (processed location)
  Pointer decreases
```

**Side Effects:**
- Modifies destination in Bank $00
- Updates `$7E3367` (decrements by count)
- Advances `[$17]` pointer by 3 bytes
- Clobbers A, X, Y registers
- No overflow protection (reading from buffer)

**Calls:**
- None (MVN is hardware instruction)

**Called By:**
- Graphics processing completion
- Buffer flush routines
- Data retrieval functions

**Related:**
- See `Memory_CopyToRAM` for forward copy (Bank $00 → Bank $7E)
- See buffer pointer management documentation
- See MVN instruction details

---

### Bitfield Manipulation

#### Bit_FindFirstSet
**Location:** Bank $00 @ ~$9932  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Find position of first set bit in 16-bit value.

**Inputs:**
- `A` (16-bit) = Value to test

**Outputs:**
- `A` (16-bit) = Bit position (0-15)

**Technical Details:**
- Right-shift algorithm, ~22-127 cycles
- **Warning:** Infinite loop if $0000

**Use Cases:** Priority detection, flag iteration

---

### Frame Synchronization

#### Field_WaitForVBlank
**Location:** Bank $01 @ $82D0  
**File:** `src/asm/banks/bank_01.asm`

**Purpose:** Synchronize code execution with VBLANK interval for safe VRAM/OAM updates.

**Inputs:**
- `$19F7` = Frame synchronization flag

**Outputs:**
- Execution paused until next VBLANK
- `$19F7` = Set to 1 after wait

**Technical Details:**
- Busy-wait loop polling frame flag
- NMI handler clears `$19F7` each VBLANK
- This function waits for clear, then sets to 1
- Preserves all processor state (PHP/PLP, PHX/PHY)
- Safe for VRAM/OAM/palette updates after return

**Process Flow:**
```asm
1. Save state:
   PHP                       ; Save processor status
   PHX                       ; Save X register
   PHY                       ; Save Y register

2. Set processor modes:
   SEP #$20                  ; 8-bit A
   REP #$10                  ; 16-bit index
   BRA Field_ProcessFrame    ; Skip to wait loop

Field_ProcessFrame:
   JSR NPC_AIIdle            ; Process NPC idle AI

Field_FrameWaitLoop:
   LDA $19F7                 ; Load frame flag
   BNE Field_FrameWaitLoop   ; Loop while non-zero

3. Flag frame processed:
   INC $19F7                 ; Set flag to 1

4. Restore and return:
   PLY                       ; Restore Y
   PLX                       ; Restore X
   PLP                       ; Restore status
   RTS
```

**Frame Synchronization System:**
```
NMI Handler (every VBLANK):
  1. STZ $19F7                ; Clear flag
  2. [VRAM/OAM transfers]
  3. RTI

Field/Battle code:
  1. Prepare graphics data
  2. JSR Field_WaitForVBlank  ; Wait here
  3. [Data transferred during VBLANK]
  4. Continue execution

Timing:
  NTSC: 60 Hz (16.67ms per frame)
  PAL: 50 Hz (20ms per frame)
  
VBLANK duration:
  ~4.5 scanlines (depends on mode)
  Enough for ~2KB VRAM transfer
```

**Frame Flag States ($19F7):**
```
$00: VBLANK occurred, safe to wait
$01: Code claimed this frame
NMI sets to $00 each VBLANK

Prevents double-processing:
  Frame N:
    NMI sets $19F7 = $00
    Code waits for $00
    Code sets $19F7 = $01
    Code executes
    
  Frame N+1:
    NMI sets $19F7 = $00
    [cycle repeats]
```

**NPC AI Integration:**
```
Field_ProcessFrame calls NPC_AIIdle:
  - Updates NPC animations
  - Processes idle movements
  - Checks player proximity
  - Non-blocking updates
  
Why before wait:
  - Utilizes CPU time during wait
  - Keeps NPCs animated
  - Distributes workload
```

**VRAM Safety:**
```
Unsafe operations (outside VBLANK):
  - VRAM writes ($2118-$2119)
  - OAM writes ($2104)
  - Palette writes ($2122)
  - Tilemap updates
  → May cause visual glitches

Safe after Field_WaitForVBlank:
  ✓ All VRAM operations
  ✓ OAM updates
  ✓ Palette changes
  ✓ PPU register writes
```

**Comparison: Field_WaitForVBlank vs Field_UpdateAndWait:**
```
Field_WaitForVBlank @ $82D0:
  - Simple VBLANK wait
  - No camera update
  - For basic sync
  
Field_UpdateAndWait @ $82D9:
  - Calls Camera_UpdatePosition first
  - Then waits for VBLANK
  - For field movement/scrolling
  
Both share code path:
  Field_UpdateAndWait:
    JSR Camera_UpdatePosition
    → Field_ProcessFrame (same as WaitForVBlank)
```

**Usage Patterns:**
```
Menu updates:
  JSR Field_WaitForVBlank
  JSR UpdateMenuGraphics

Sprite updates:
  JSR Field_WaitForVBlank
  JSR UpdateOAM

Tilemap changes:
  JSR Field_WaitForVBlank
  JSR WriteTilemap

Multiple operations:
  JSR Field_WaitForVBlank
  JSR UpdatePalette
  JSR UpdateTilemap
  JSR UpdateOAM
  ; All safe in same VBLANK
```

**Side Effects:**
- Blocks execution until VBLANK
- Sets `$19F7` = 1
- Calls `NPC_AIIdle` @ $A081
- Preserves all registers (PHP/PLP, PHX/PHY)

**Calls:**
- `NPC_AIIdle` @ $01:$A081 (JSR) - Process NPC idle state

**Called By:**
- Map event processing
- Field rendering
- Menu updates
- Graphics transfers
- Called 20+ times throughout Bank $01

**Related:**
- See `Field_UpdateAndWait` @ $82D9 for camera-aware variant
- See NMI handler for flag clearing
- See VRAM transfer routines
- See frame timing documentation

---

## Index by Bank

### Bank $00 - System/Core
- `Random` @ $8456 - Random number generator
- `RNG_GenerateRandom` @ $9783 - RNG with modulo operation
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
- `Cursor_UpdateComplete` @ $8A9C - Validate cursor position
- `Cursor_UpdateSprite` @ $8C3D - Render cursor sprite
- `Memory_Copy64Bytes` @ $A216 - Fast 64-byte block copy
- `Memory_Copy32Bytes` @ $A24A - Fast 32-byte block copy
- `Memory_CopyToRAM` @ $A89B - MVN copy Bank $00 → $7E
- `Memory_CopyFromRAM` @ $A8AB - MVN copy Bank $7E → $00
- `Palette_Load8Colors` @ $A14B - Fast 8-color palette load
- `Graphics_TransferBattleMode` @ Section 2 - DMA battle graphics upload
- `Graphics_UpdateFieldMode` @ Section 2 - Conditional field graphics DMA
- `Bit_FindFirstSet` @ $9932 - Find first set bit position

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
- `Field_EntityCollision` @ $8DF3 - Entity collision waiting
- `Field_CheckTileCollision` @ $9038 - Tile collision lookup
- `Field_TileCollisionLoop` @ $9058 - Coordinate to tile conversion
- `Field_CheckEntityCollision` @ $90DD - Entity collision lookup
- `Field_CameraScroll` @ $8B76 - Disable camera scrolling
- `Field_CameraUpdate` @ $8B83 - Enable camera scrolling
- `Field_CameraCalculate` @ $8B90 - Calculate camera position
- `Field_ProcessNPCInteraction` @ $E404 - Initialize NPC interaction
- `Field_WaitForVBlank` @ $82D0 - VBLANK synchronization
- `Battle_CalculateDamage` @ $C488 - Extract damage type and base value

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
- `Battle_ProcessElementalDamage` @ $94D6 - Elemental damage system
- `Battle_CheckWeaknessFlags` @ $A97F - Weakness detection
- `Battle_DeathResistCheck` @ $999D - Death immunity check
- `Battle_ProcessMuteSpell` @ $9B28 - Mute check (physical)
- `Battle_MuteApplied` @ $9B34 - Mute check (spells)
- `Battle_CurePoison` @ $97B2 - Poison status handling
- `Battle_ReflectSpell` @ $9BED - Spell reflection
- `Battle_ProcessPetrifySpell` @ $99DA - Petrification
- `Battle_ProcessPoison` @ $8532 - Load poison entity status
- `Battle_CalculatePoisonDamage` @ $853D - Calculate poison damage
- `Battle_ProcessParalysis` @ $8486 - Paralysis effect handling
- `Battle_CheckPoison` @ $8522 - Poison status orchestration
- `Battle_CalculateDamage` @ $93FD - Attack vs defense calculation
- `Battle_CheckCriticalHit` @ $9495 - Critical hit determination

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
- `BattleSprite_UpdateOAM` @ $8077 - Update sprite OAM data
- `BattleSprite_Animate` @ $803F - Sprite animation system
- See `src/asm/bank_0B_documented.asm` for battle-specific graphics

### Bank $0C - Mode 7/World Map
- `Display_WaitVBlankAndUpdate` @ $85DB - VBLANK sync + sprite animation
- `Display_Mode7TilemapSetup` @ $87ED - Mode 7 tilemap fill & HDMA setup
- `Display_Mode7MatrixInit` @ $88BE - Mode 7 matrix initialization
- `Display_Mode7RotationSequence` @ $896F - Animated rotation effect
- See `src/asm/bank_0C_documented.asm` for Mode 7 functions

### Bank $0D - Sound/APU
- `SPC_InitMain` @ $802C - SPC700 driver upload & initialization
- `APU_SendCommand` @ $8147 - Music/SFX command dispatcher
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
- `Graphics_TransferBattleMode` (Bank $00 @ Section 2) - DMA battle graphics
- `Graphics_UpdateFieldMode` (Bank $00 @ Section 2) - DMA field graphics
- `Display_Mode7TilemapSetup` (Bank $0C @ $87ED) - Mode 7 tilemap & HDMA
- `Display_Mode7MatrixInit` (Bank $0C @ $88BE) - Mode 7 matrix setup
- `Display_Mode7RotationSequence` (Bank $0C @ $896F) - Rotation animation

### Map & World
- `LoadMap` (Bank $06 @ $A000)
- `CheckCollision` (Bank $06 @ $B234)
- `GetTileProperties` (Bank $06 @ $B456)
- `UpdateNPCs` (Bank $06 @ $C000)
- `CheckPlayerProximity` (Bank $06 @ $C234)
- `Field_CameraScroll` (Bank $01 @ $8B76)
- `Field_CameraUpdate` (Bank $01 @ $8B83)
- `Field_CameraCalculate` (Bank $01 @ $8B90)
- `Field_ProcessNPCInteraction` (Bank $01 @ $E404)

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
- `Field_EntityCollision` (Bank $01 @ $8DF3)
- `Field_CheckTileCollision` (Bank $01 @ $9038)
- `Field_TileCollisionLoop` (Bank $01 @ $9058)
- `Field_CheckEntityCollision` (Bank $01 @ $90DD)

### Battle Items & Effects
- `Battle_UseItem` (Bank $02 @ $926D)
- `Battle_ApplyItemEffect` (Bank $02 @ $931D)
- `Battle_CureMute` (Bank $02 @ $97BE)
- `Battle_CureParalysis` (Bank $02 @ $97B8)
- `Battle_CalculateHitChance` (Bank $02 @ $A0E1)
- `Battle_CheckTargetDeath` (Bank $02 @ $95DE)
- `Battle_InitializeAnimation` (Bank $02 @ $9C9B)
- `Battle_ApplyStatDebuff` (Bank $02 @ $9964)
- `Battle_ProcessPoison` (Bank $02 @ $8532)
- `Battle_CalculatePoisonDamage` (Bank $02 @ $853D)
- `Battle_ProcessParalysis` (Bank $02 @ $8486)
- `Battle_CheckPoison` (Bank $02 @ $8522)

### Sprite & Graphics
- `BattleSprite_UpdateOAM` (Bank $0B @ $8077)
- `BattleSprite_Animate` (Bank $0B @ $803F)
- `LoadTileset` (Bank $07 @ $8000)
- `LoadPalette` (Bank $05 @ $A000)
- `DecompressGraphics` (Bank $07 @ $8234)
- `Battle_LoadGraphics` (Bank $01 @ $8244)
- `UpdateOAM` (Bank $00 @ $9234)

### Battle Damage & Elements
- `CalculatePhysicalDamage` (Bank $02 @ $C500)
- `CalculateMagicDamage` (Bank $02 @ $C600)
- `Battle_CalculateDamage` (Bank $01 @ $C488) - Parameter extraction
- `Battle_CalculateDamage` (Bank $02 @ $93FD) - Attack vs defense
- `Battle_CheckCriticalHit` (Bank $02 @ $9495) - Critical determination
- `Battle_ProcessElementalDamage` (Bank $02 @ $94D6)
- `Battle_CheckWeaknessFlags` (Bank $02 @ $A97F)
- `Battle_DeathResistCheck` (Bank $02 @ $999D)
- `Battle_ReflectSpell` (Bank $02 @ $9BED)

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

### Sound & Animation
- `SPC_InitMain` (Bank $0D @ $802C) - SPC700 driver upload
- `APU_SendCommand` (Bank $0D @ $8147) - Music/SFX commands
- `Display_WaitVBlankAndUpdate` (Bank $0C @ $85DB) - VBLANK sync + sprite animation

### Utilities
- `Random` (Bank $00 @ $8456)
- `RNG_GenerateRandom` (Bank $00 @ $9783)
- `Bit_FindFirstSet` (Bank $00 @ $9932) - Find first set bit
- `Battle_WaitVBlank` (Bank $01 @ $8449)
- `Field_WaitForVBlank` (Bank $01 @ $82D0)
- `Bitfield_SetBits` (Bank $00 @ $974E)
- `Cursor_UpdateComplete` (Bank $00 @ $8A9C) - Cursor validation
- `Cursor_UpdateSprite` (Bank $00 @ $8C3D) - Cursor rendering
- `Memory_Copy64Bytes` (Bank $00 @ $A216) - Fast 64-byte copy
- `Memory_Copy32Bytes` (Bank $00 @ $A24A) - Fast 32-byte copy
- `Memory_CopyToRAM` (Bank $00 @ $A89B) - MVN to RAM
- `Memory_CopyFromRAM` (Bank $00 @ $A8AB) - MVN from RAM

---

## Contributing

This function reference is automatically updated as code is documented. To add or update function documentation:

1. Add proper function header comments in ASM files
2. Follow the documentation standard shown in [Overview](#overview)
3. Run `python tools/analyze_doc_coverage.py` to verify
4. Functions with complete headers will appear in this reference

See `docs/DOCUMENTATION_UPDATE_CHECKLIST.md` for complete guidelines.

---

**Note:** This is a living document. Not all functions are documented yet. Current coverage: **~26.7%** (2,175+ / 8,153 functions).

**Recent Additions (2025-11-05 - Update #14):**
- Added 2 DMA graphics transfer functions
- Graphics_TransferBattleMode: Battle graphics upload via DMA (3,456 bytes, ~2% frame)
- Graphics_UpdateFieldMode: Conditional field graphics with state-based branching

**Recent Additions (2025-11-05 - Update #13):**
- Added 3 critical sound & animation functions
- SPC_InitMain: Complete SPC700 driver upload with IPL handshake protocol
- APU_SendCommand: Music/SFX command dispatcher with full command table
- Display_WaitVBlankAndUpdate: VBLANK sync + 5-sprite animation system (14 frames)

**Recent Additions (2025-11-05 - Update #12):**
- Added 1 graphics system function (palette loading)
- Palette_Load8Colors: Fast 8-color CGRAM load for UI/text
- Cursor_UpdateSprite (Bank $00): Visual cursor rendering in battle/field

**Recent Additions (2025-11-05 - Update #9):**
- Added 2 utility functions (RNG and VBlank synchronization)
- RNG_GenerateRandom: Pseudo-random generation with modulo
- Field_WaitForVBlank: Frame synchronization for VRAM safety

**Next Priority Areas:**
- Animation system functions
- Text rendering pipeline
- Sound/music control
- More DMA operations

For undocumented functions, see the source ASM files directly in `src/asm/`.
