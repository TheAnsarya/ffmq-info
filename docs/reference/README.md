# Reference Documentation

This directory contains technical reference materials including data structures, system constants, hardware registers, coding standards, and label conventions for the Final Fantasy Mystic Quest disassembly project.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Reference](#quick-reference)
- [Documentation Index](#documentation-index)
  - [Data Specifications](#data-specifications)
  - [System Reference](#system-reference)
  - [Code Standards](#code-standards)
  - [Label Documentation](#label-documentation)
  - [Analysis Reports](#analysis-reports)
- [Common Lookups](#common-lookups)
- [Data Structure Reference](#data-structure-reference)
- [Hardware Reference](#hardware-reference)
- [Related Documentation](#related-documentation)

---

## Overview

This reference documentation provides detailed technical specifications for all data structures, system constants, hardware registers, and coding conventions used in the FFMQ disassembly.

**Reference Categories:**
- **Data Structures** - All game data formats and layouts
- **System Constants** - Memory addresses, flags, IDs
- **Hardware Registers** - SNES PPU, APU, DMA registers
- **Coding Standards** - Assembly style guide, conventions
- **Label Index** - Complete label documentation
- **Analysis Reports** - Code analysis and catalogs

---

## Quick Reference

### Find a Data Structure
```bash
# Search data structures documentation
grep -i "enemy" docs/reference/DATA_STRUCTURES.md

# View specific structure
python tools/analysis/view_structure.py --type enemy
```

### Look Up System Constant
```bash
# Search constants
grep "ITEM_" docs/reference/SYSTEM_CONSTANTS.md

# List all constants of a type
grep "^ITEM_" src/include/constants.asm
```

### Find Hardware Register
```bash
# Search hardware registers
grep "INIDISP" docs/reference/HARDWARE_REGISTER_STANDARDIZATION.md

# View register details
python tools/analysis/hardware_register_info.py --register INIDISP
```

### Check Coding Standard
```bash
# View coding standards
cat docs/reference/coding-standards.md

# Validate code against standards
python tools/formatting/check_standards.py src/bank_02.asm
```

---

## Documentation Index

### Data Specifications

#### [`DATA_STRUCTURES.md`](DATA_STRUCTURES.md) 📊 **PRIMARY REFERENCE**
*Complete data structure specifications*

**Contents:**
- All game data structures
- Binary format specifications
- Field descriptions and valid ranges
- Usage examples
- Memory layouts
- Structure relationships

**Use when:**
- Understanding data formats
- Writing data extraction tools
- Modifying game data
- Debugging data issues

**Structure Categories:**

**1. Character Data:**

**Player Character Structure (32 bytes):**
```
Offset  Size  Field Name        Description
------  ----  ----------        -----------
0x00    2     max_hp            Maximum HP (1-9999)
0x02    2     current_hp        Current HP (0-max_hp)
0x04    2     max_mp            Maximum MP (0-999)
0x06    2     current_mp        Current MP (0-max_mp)
0x08    1     attack            Attack power (0-255)
0x09    1     defense           Defense power (0-255)
0x0A    1     magic             Magic power (0-255)
0x0B    1     magic_defense     Magic defense (0-255)
0x0C    1     agility           Agility/Speed (0-255)
0x0D    1     accuracy          Hit accuracy (0-255)
0x0E    1     evasion           Evasion rate (0-255)
0x0F    1     level             Character level (1-99)
0x10    4     experience        Total EXP (0-9999999)
0x14    1     weapon_equipped   Weapon ID (0-15)
0x15    1     armor_equipped    Armor ID (0-15)
0x16    1     accessory_equipped Accessory ID (0-15)
0x17    1     status_flags      Status conditions (bit flags)
0x18    8     learned_spells    Spell flags (64 spells)

Example (Benjamin at level 10):
00 C8  64 00  00 1E  00 1E  28 1E 32 28  3C 50 40 0A
│      │      │      │      │  │  │  │   │  │  │  └─ Level 10
│      │      │      │      │  │  │  │   │  │  └─ Evasion 64
│      │      │      │      │  │  │  │   │  └─ Accuracy 80
│      │      │      │      │  │  │  │   └─ Agility 60
│      │      │      │      │  │  │  └─ Magic Defense 40
│      │      │      │      │  │  └─ Magic 50
│      │      │      │      │  └─ Defense 30
│      │      │      │      └─ Attack 40
│      │      │      └─ Max MP: 30
│      │      └─ Current MP: 30
│      └─ Current HP: 100
└─ Max HP: 200
```

**2. Enemy Data:**

**Enemy Structure (16 bytes):**
```
Offset  Size  Field Name        Description
------  ----  ----------        -----------
0x00    2     hp                Max HP (1-9999)
0x02    1     attack            Attack power (0-255)
0x03    1     defense           Defense power (0-255)
0x04    1     magic             Magic power (0-255)
0x05    1     magic_defense     Magic defense (0-255)
0x06    1     agility           Agility/Speed (0-255)
0x07    1     elemental_flags   Element weak/resist (bit flags)
0x08    2     experience        EXP reward (0-65535)
0x0A    2     gold              Gold reward (0-65535)
0x0C    1     ai_script         AI script ID (0-255)
0x0D    1     sprite_id         Graphics ID (0-255)
0x0E    1     palette_id        Palette ID (0-15)
0x0F    1     drop_table        Item drop table ID (0-255)

Element Flags (0x07):
Bit 0-3: Weakness  (Fire, Ice, Thunder, Earth)
Bit 4-7: Resistance (Fire, Ice, Thunder, Earth)

Example (Goblin):
00 32  1E 14  0A 0F  19 01  00 0F  00 0A  00 05  03 00
│      │  │   │  │   │  └─ Fire weakness
│      │  │   │  └─ Agility 25
│      │  │   └─ Magic Defense 15
│      │  └─ Magic 10
│      └─ Defense 20
└─ HP: 50

EXP: 15, Gold: 10, AI: 0, Sprite: 5, Palette: 3, Drops: 0
```

**3. Item Data:**

**Item Structure (8 bytes):**
```
Offset  Size  Field Name      Description
------  ----  ----------      -----------
0x00    1     type            Item type (consumable, equipment, etc.)
0x01    1     power           Effect power / stat bonus
0x02    2     buy_price       Buy price (0-65535)
0x04    2     sell_price      Sell price (0-65535)
0x06    1     icon_id         Icon graphic ID
0x07    1     flags           Item flags (bit flags)

Item Types:
0x00: Consumable (potion, etc.)
0x01: Weapon
0x02: Armor
0x03: Accessory
0x04: Key item
0x05: Special

Flags (0x07):
Bit 0: Usable in battle
Bit 1: Usable in menu
Bit 2: Can be discarded
Bit 3: Can be sold
Bit 4-7: Reserved

Example (Cure Potion):
00 1E  00 14  00 0A  05 07
│  │   │      │      │  └─ Flags: 0x07 (usable, discardable, sellable)
│  │   │      │      └─ Icon: 5
│  │   │      └─ Sell price: 10
│  │   └─ Buy price: 20
│  └─ Power: 30 HP restored
└─ Type: Consumable
```

**4. Spell Data:**

**Spell Structure (12 bytes):**
```
Offset  Size  Field Name      Description
------  ----  ----------      -----------
0x00    1     spell_id        Spell ID (0-255)
0x01    1     mp_cost         MP required (0-99)
0x02    2     power           Spell power (0-999)
0x04    1     element         Element type (bit flags)
0x05    1     target          Target type (single/all)
0x06    1     animation_id    Animation ID
0x07    1     sound_effect    Sound effect ID
0x08    2     flags           Spell properties
0x0A    2     reserved        Reserved/padding

Element Flags:
Bit 0: Fire
Bit 1: Ice
Bit 2: Thunder
Bit 3: Earth
Bit 4: Holy
Bit 5: Dark
Bit 6-7: Unused

Target Types:
0x00: Single enemy
0x01: All enemies
0x02: Single ally
0x03: All allies
0x04: Self

Example (Fire spell):
00 04  00 1E  01 00  05 0C  00 00  00 00
│  │   │      │  │   │  │   │
│  │   │      │  │   │  │   └─ Flags
│  │   │      │  │   │  └─ Sound: 12
│  │   │      │  │   └─ Animation: 5
│  │   │      │  └─ Target: Single enemy
│  │   │      └─ Element: Fire (bit 0)
│  │   └─ Power: 30
│  └─ MP Cost: 4
└─ Spell ID: 0
```

**5. Map Data:**

**Map Header (32 bytes):**
```
Offset  Size  Field Name          Description
------  ----  ----------          -----------
0x00    2     map_id              Map ID (0-255)
0x02    2     width               Width in tiles (1-64)
0x04    2     height              Height in tiles (1-64)
0x06    2     tileset_id          Tileset to use
0x08    2     palette_id          Palette to use
0x0A    2     music_id            Background music
0x0C    4     tilemap_ptr         Pointer to tilemap data
0x10    4     collision_ptr       Pointer to collision data
0x14    4     event_ptr           Pointer to event data
0x18    1     layers              Number of layers (1-3)
0x19    1     scroll_type         Scrolling behavior
0x1A    2     bg1_config          Background 1 config
0x1C    2     bg2_config          Background 2 config
0x1E    2     flags               Map flags

Example (Foresta Town):
05 00  20 00  20 00  03 00  02 00  08 00
│      │      │      │      │      └─ Music: Track 8
│      │      │      │      └─ Palette: 2
│      │      │      └─ Tileset: 3
│      │      └─ Height: 32 tiles
│      └─ Width: 32 tiles
└─ Map ID: 5

[Pointers to tilemap, collision, events follow]
```

**6. Equipment Data:**

**Weapon Structure (12 bytes):**
```
Offset  Size  Field Name      Description
------  ----  ----------      -----------
0x00    1     weapon_id       Weapon ID (0-15)
0x01    1     type            Weapon type (sword, axe, bomb, claw)
0x02    2     attack_bonus    Attack power bonus
0x04    2     buy_price       Purchase price
0x06    2     sell_price      Sell price
0x08    1     special_effect  Special ability ID
0x09    1     element         Elemental property
0x0A    1     icon_id         Icon graphic
0x0B    1     flags           Equipment flags

Weapon Types:
0x00: Sword
0x01: Axe
0x02: Bomb
0x03: Claw

Example (Steel Sword):
01 00  00 32  01 90  00 C8  00 00  08 01
│  │   │      │      │      │  │   │  └─ Flags
│  │   │      │      │      │  │   └─ Icon: 8
│  │   │      │      │      │  └─ Element: None
│  │   │      │      │      └─ Special: None
│  │   │      │      └─ Sell: 200
│  │   │      └─ Buy: 400
│  │   └─ Attack: +50
│  └─ Type: Sword
└─ ID: 1
```

**7. Battle Formation:**

**Formation Structure (8 bytes):**
```
Offset  Size  Field Name      Description
------  ----  ----------      -----------
0x00    1     formation_id    Formation ID
0x01    1     enemy_count     Number of enemies (1-6)
0x02    1     enemy_1_id      First enemy ID
0x03    1     enemy_2_id      Second enemy ID (0xFF = none)
0x04    1     enemy_3_id      Third enemy ID (0xFF = none)
0x05    1     enemy_4_id      Fourth enemy ID (0xFF = none)
0x06    1     background_id   Battle background
0x07    1     flags           Formation flags

Example (3 Goblins):
00 03  00 00 00  FF FF  02 00
│  │   │  │  │   │  │   │  └─ Flags
│  │   │  │  │   │  │   └─ Background: 2
│  │   │  │  │   │  └─ Enemy 4: None
│  │   │  │  │   └─ Enemy 3: None
│  │   │  │  └─ Enemy 2: Goblin (0)
│  │   │  └─ Enemy 1: Goblin (0)
│  │   └─ Enemy 0: Goblin (0)
│  └─ Count: 3
└─ Formation ID: 0
```

**8. Event Data:**

**Event Structure (variable size):**
```
Offset  Size  Field Name      Description
------  ----  ----------      -----------
0x00    1     event_type      Type of event (NPC, chest, warp, etc.)
0x01    2     x_position      X coordinate
0x03    2     y_position      Y coordinate
0x05    ...   type_specific   Data specific to event type

Event Types:
0x00: NPC dialogue
0x01: Chest
0x02: Warp point
0x03: Trigger zone
0x04: Battle trigger
0x05: Cutscene
0x06: Script

NPC Event (+6 bytes):
0x05    1     sprite_id       NPC sprite
0x06    1     direction       Facing direction
0x07    2     dialogue_ptr    Pointer to dialogue
0x09    1     script_id       Event script ID
0x0A    1     flags           NPC flags

Chest Event (+4 bytes):
0x05    1     item_id         Item to give
0x06    1     item_count      Quantity
0x07    2     flag_id         Game flag to set when opened

Warp Event (+6 bytes):
0x05    1     dest_map_id     Destination map
0x06    2     dest_x          Destination X
0x08    2     dest_y          Destination Y
0x0A    1     animation       Transition effect
```

---

#### [`data_formats.md`](data_formats.md) 📐 Data Formats
*Detailed data format specifications*

**Contents:**
- Binary data formats
- Encoding schemes
- Compression formats
- Pointer structures
- Endianness conventions

**Use when:**
- Implementing parsers
- Writing converters
- Understanding binary data
- Debugging format issues

**Common Data Formats:**

**1. Little-Endian 16-bit Integers:**
```
Value: 0x1234 (4660 decimal)
Storage: 34 12 (low byte first)

Reading:
value = byte[0] | (byte[1] << 8)
value = 0x34 | (0x12 << 8)
value = 52 | 4608
value = 4660

Writing:
byte[0] = value & 0xFF        // Low byte
byte[1] = (value >> 8) & 0xFF // High byte
```

**2. Bit Flags:**
```
8-bit flag byte:
Bit 7 6 5 4 3 2 1 0
    │ │ │ │ │ │ │ └─ Flag 0
    │ │ │ │ │ │ └─── Flag 1
    │ │ │ │ │ └───── Flag 2
    │ │ │ │ └─────── Flag 3
    │ │ │ └───────── Flag 4
    │ │ └─────────── Flag 5
    │ └───────────── Flag 6
    └─────────────── Flag 7

Setting flag 3:
value |= (1 << 3)  // value OR 0x08

Clearing flag 3:
value &= ~(1 << 3)  // value AND NOT 0x08

Testing flag 3:
if (value & (1 << 3)) { /* flag is set */ }
```

**3. Packed Data:**
```
Two 4-bit values in one byte:
Byte: 0x3A = 0011 1010
      │    │    │
      │    └────┴─ Low nibble: 0xA (10)
      └────────── High nibble: 0x3 (3)

Extracting:
low_nibble = value & 0x0F
high_nibble = (value >> 4) & 0x0F

Packing:
value = (high_nibble << 4) | low_nibble
value = (3 << 4) | 10
value = 48 | 10
value = 58 (0x3A)
```

**4. RLE Compression:**
```
Format:
Control byte:
  0x00-0x7F: Literal run (copy next N+1 bytes)
  0x80-0xFF: RLE run (repeat next byte N-127 times)

Example compression:
Input:  AA AA AA AA BB CC DD DD DD EE
Compressed: 83 AA 00 BB 00 CC 82 DD 00 EE

Decompression algorithm:
while (input remaining):
    control = read_byte()
    if (control < 0x80):
        # Literal run
        count = control + 1
        copy_bytes(count)
    else:
        # RLE run
        count = control - 0x80 + 1
        value = read_byte()
        repeat_byte(value, count)
```

**5. SNES Address Formats:**
```
PC Address (ROM file offset):
0x012345 = Offset 0x12345 in ROM file

SNES Address (CPU memory address):
$02:8345 = Bank $02, offset $8345

LoROM mapping:
PC = ((SNES_bank * 0x8000) + (SNES_offset - 0x8000))

Example:
SNES: $02:8345
PC = (0x02 * 0x8000) + (0x8345 - 0x8000)
PC = 0x10000 + 0x0345
PC = 0x10345

Reverse (PC to SNES):
SNES_bank = PC / 0x8000
SNES_offset = (PC % 0x8000) + 0x8000

Example:
PC: 0x10345
Bank = 0x10345 / 0x8000 = 2
Offset = (0x10345 % 0x8000) + 0x8000 = 0x0345 + 0x8000 = 0x8345
SNES: $02:8345
```

**6. String Encoding:**
```
Null-terminated strings:
"Hello" = 48 65 6C 6C 6F 00
           H  e  l  l  o  \0

Length-prefixed strings:
"Hello" = 05 48 65 6C 6C 6F
          │  H  e  l  l  o
          └─ Length: 5

Control codes in strings:
0x01: Newline
0x02: Wait for button
0x03: Clear text box
0x04: Player name
0x05: Variable/number

Example:
"HP: \x06\n" = 48 50 3A 20 06 01
               H  P  :  space <var> <newline>
```

---

### System Reference

#### [`SYSTEM_CONSTANTS.md`](SYSTEM_CONSTANTS.md) 🔢 System Constants
*All system-wide constants and definitions*

**Contents:**
- Memory addresses
- Item IDs
- Enemy IDs
- Spell IDs
- Map IDs
- Sound IDs
- Game flags
- Status effect constants

**Use when:**
- Writing code or scripts
- Looking up IDs
- Understanding constants
- Creating data tables

**Constant Categories:**

**1. Memory Addresses:**

**RAM Addresses:**
```asm
; Character data
CharacterData_Base          = $7E1000
CharacterData_Benjamin      = $7E1000
CharacterData_Companion     = $7E1020
CharacterHP                 = $7E1000  ; 2 bytes
CharacterMP                 = $7E1002  ; 2 bytes
CharacterLevel              = $7E100F  ; 1 byte

; Battle state
BattleState_Base            = $7E0100
EnemyHP_Current             = $7E0200  ; 6 enemies × 2 bytes
EnemyStatus                 = $7E0210  ; 6 enemies × 1 byte
BattleFlags                 = $7E0100  ; 1 byte
TurnCounter                 = $7E0101  ; 2 bytes

; Inventory
Inventory_Base              = $7E1100
Inventory_Items             = $7E1100  ; 64 items × 1 byte
Inventory_Counts            = $7E1140  ; 64 counts × 1 byte
EquippedWeapon              = $7E1180  ; 1 byte
EquippedArmor               = $7E1181  ; 1 byte
EquippedAccessory           = $7E1182  ; 1 byte

; Game state
GameFlags_Base              = $7E1200
CurrentMap                  = $7E1200  ; 2 bytes
PlayerX                     = $7E1202  ; 2 bytes
PlayerY                     = $7E1204  ; 2 bytes
Gold                        = $7E1206  ; 4 bytes
GameProgress                = $7E120A  ; 2 bytes (story flags)
```

**ROM Addresses:**
```asm
; Data tables
EnemyStatsTable             = $028000  ; Bank $02
ItemDataTable               = $048000  ; Bank $04
SpellDataTable              = $058000  ; Bank $05
MapHeaderTable              = $038000  ; Bank $03
TextPointerTable            = $088000  ; Bank $08

; Code entry points
ResetVector                 = $008000  ; Bank $00
NMIHandler                  = $008100  ; Bank $00
IRQHandler                  = $008200  ; Bank $00

; Graphics data
CharacterGraphics           = $0C8000  ; Bank $0C
EnemyGraphics               = $0D8000  ; Bank $0D
UIGraphics                  = $0E8000  ; Bank $0E
BackgroundGraphics          = $0F8000  ; Bank $0F
```

**2. Item IDs:**
```asm
; Consumables
ITEM_CURE_POTION            = $00
ITEM_HEAL_POTION            = $01
ITEM_SEED                   = $02
ITEM_REFRESHER              = $03
ITEM_ELIXIR                 = $04

; Weapons
ITEM_STEEL_SWORD            = $10
ITEM_KNIGHT_SWORD           = $11
ITEM_EXCALIBUR              = $12
ITEM_BATTLEAXE              = $13
ITEM_DRAGON_CLAW            = $14
ITEM_BOMB                   = $15

; Armor
ITEM_LEATHER_ARMOR          = $20
ITEM_STEEL_ARMOR            = $21
ITEM_KNIGHT_ARMOR           = $22
ITEM_GAEA_ARMOR             = $23

; Accessories
ITEM_CHARM                  = $30
ITEM_MAGIC_RING             = $31
ITEM_CUPID_LOCKET           = $32
ITEM_RAINB_RIBBON           = $33

; Key items
ITEM_ELIXIR_KEY             = $40
ITEM_CRYSTAL_KEY            = $41
ITEM_THUNDER_ROCK           = $42
```

**3. Enemy IDs:**
```asm
; Regular enemies
ENEMY_GOBLIN                = $00
ENEMY_SNAKE                 = $01
ENEMY_BEE                   = $02
ENEMY_LIZARD                = $03
ENEMY_ORC                   = $04
ENEMY_SKELETON              = $05

; Mid-tier enemies
ENEMY_GARGOYLE              = $20
ENEMY_GOLEM                 = $21
ENEMY_CHIMERA               = $22
ENEMY_HYDRA                 = $23

; Bosses
ENEMY_MINOTAUR              = $40
ENEMY_FLAMERUS_REX          = $41
ENEMY_ICE_GOLEM             = $42
ENEMY_PAZUZU                = $43
ENEMY_DARK_KING             = $44
```

**4. Spell IDs:**
```asm
; White magic
SPELL_CURE                  = $00
SPELL_CURE2                 = $01
SPELL_CURE3                 = $02
SPELL_LIFE                  = $03
SPELL_HEAL                  = $04
SPELL_REFRESH               = $05

; Black magic
SPELL_FIRE                  = $10
SPELL_FIRE2                 = $11
SPELL_ICE                   = $12
SPELL_ICE2                  = $13
SPELL_THUNDER               = $14
SPELL_THUNDER2              = $15

; Wizard magic
SPELL_FLARE                 = $20
SPELL_BLIZZARD              = $21
SPELL_MEGA                  = $22
SPELL_WHITE                 = $23
SPELL_METEOR                = $24
SPELL_QUAKE                 = $25
```

**5. Status Effect Flags:**
```asm
; Status effect bit flags
STATUS_NORMAL               = $00
STATUS_POISON               = $01  ; Bit 0
STATUS_SLEEP                = $02  ; Bit 1
STATUS_PARALYSIS            = $04  ; Bit 2
STATUS_BLIND                = $08  ; Bit 3
STATUS_SILENCE              = $10  ; Bit 4
STATUS_CONFUSION            = $20  ; Bit 5
STATUS_DEATH                = $40  ; Bit 6
STATUS_PETRIFY              = $80  ; Bit 7
```

**6. Map IDs:**
```asm
MAP_HILL_OF_FATE            = $00
MAP_FORESTA_TOWN            = $01
MAP_FORESTA_HOUSE           = $02
MAP_SAND_TEMPLE             = $03
MAP_BONE_DUNGEON            = $04
MAP_FOCUS_TOWER             = $05
MAP_AQUARIA                 = $06
MAP_WINTRY_CAVE             = $07
MAP_LIFE_TEMPLE             = $08
MAP_FALLS_BASIN             = $09
MAP_MINE                    = $0A
MAP_SEALED_TEMPLE           = $0B
MAP_VOLCANO                 = $0C
MAP_LAVA_DOME               = $0D
MAP_FIREBURG                = $0E
MAP_DARK_KING_PALACE        = $0F
```

**7. Game Progress Flags:**
```asm
; Story progression flags
FLAG_GAME_STARTED           = $0001
FLAG_MET_OLD_MAN            = $0002
FLAG_GOT_STEEL_SWORD        = $0004
FLAG_DEFEATED_MINOTAUR      = $0008
FLAG_RESCUED_KAELI          = $0010
FLAG_FORESTA_CLEAR          = $0020
FLAG_AQUARIA_STARTED        = $0040
FLAG_DEFEATED_ICE_GOLEM     = $0080
FLAG_AQUARIA_CLEAR          = $0100
FLAG_FIREBURG_STARTED       = $0200
FLAG_DEFEATED_FLAMERUS      = $0400
FLAG_FIREBURG_CLEAR         = $0800
FLAG_WINDIA_STARTED         = $1000
FLAG_DEFEATED_PAZUZU        = $2000
FLAG_WINDIA_CLEAR           = $4000
FLAG_FINAL_BATTLE           = $8000
```

---

#### [`RAM_MAP.md`](RAM_MAP.md) 🗺️ RAM Memory Map
*Complete RAM memory layout documentation*

**Contents:**
- RAM organization
- Variable locations
- Buffer addresses
- Stack usage
- Free RAM areas

**Use when:**
- Understanding memory usage
- Finding variables
- Adding new data
- Debugging RAM issues

**RAM Organization ($7E0000-$7FFFFF, 128KB total):**

**$7E0000-$7E1FFF: System and Low RAM (8KB):**
```
$7E0000-$7E00FF: Zero Page (256 bytes)
- Fast access variables
- Temporary calculations
- Function parameters

$7E0100-$7E01FF: Battle State (256 bytes)
- Current battle flags
- Turn counters
- Temporary battle data

$7E0200-$7E03FF: Enemy Data (512 bytes)
- Enemy HP, MP, status
- AI state variables
- Attack timers

$7E0400-$7E05FF: PPU Buffers (512 bytes)
- DMA transfer staging
- PPU register shadows
- Graphics update queue

$7E0600-$7E07FF: Sound (512 bytes)
- Sound effect queue
- Music state
- Volume controls

$7E0800-$7E0FFF: System Variables (2KB)
- Input state
- RNG state
- Frame counters
- System flags
```

**$7E1000-$7E1FFF: Game State (4KB):**
```
$7E1000-$7E103F: Benjamin Data (64 bytes)
- HP, MP, stats
- Equipment
- Learned spells

$7E1040-$7E107F: Companion Data (64 bytes)
- HP, MP, stats
- Equipment
- Learned spells

$7E1080-$7E10FF: Party State (128 bytes)
- Formation
- Status effects
- Buffs/debuffs

$7E1100-$7E11FF: Inventory (256 bytes)
- Items (64 slots)
- Counts (64 bytes)
- Equipment slots

$7E1200-$7E12FF: World State (256 bytes)
- Current map
- Player position
- Gold
- Game progress flags

$7E1300-$7E13FF: Event State (256 bytes)
- Triggered events
- Chest opened flags
- NPC states

$7E1400-$7E1FFF: Save Data Mirror (3KB)
- Copy of save data
- Backup during save
```

**$7E2000-$7E7FFF: Buffers and Work RAM (24KB):**
```
$7E2000-$7E3FFF: Map Data Buffer (8KB)
- Decompressed map tiles
- Collision data
- Event data

$7E4000-$7E5FFF: Graphics Buffers (8KB)
- Sprite data
- Tile update buffer
- Palette buffer

$7E6000-$7E6FFF: Text Buffer (4KB)
- Decompressed text strings
- Text rendering buffer

$7E7000-$7E77FF: Stack (2KB)
- System stack
- Return addresses
- Local variables

$7E7800-$7E7FFF: Free RAM (2KB)
- Available for expansion
- Temporary large buffers
```

---

#### [`HARDWARE_REGISTER_STANDARDIZATION.md`](HARDWARE_REGISTER_STANDARDIZATION.md) ⚙️ Hardware Registers
*SNES hardware register reference*

**Contents:**
- PPU registers
- APU registers
- DMA registers
- Controller registers
- Register usage conventions
- Initialization sequences

**Use when:**
- Writing hardware code
- Understanding graphics/sound code
- Debugging hardware issues
- Adding new features

**PPU Registers:**

**Display Control:**
```asm
; $2100: INIDISP - Display Control
; Bit 7: Force blank (1 = blank)
; Bits 0-3: Brightness (0-15)

INIDISP                     = $2100

; Example usage:
LDA #$80                    ; Force blank
STA INIDISP
; ... upload graphics ...
LDA #$0F                    ; Max brightness, display on
STA INIDISP
```

**Background Mode:**
```asm
; $2105: BGMODE - BG Mode and Character Size
; Bits 0-2: BG mode (0-7)
; Bit 3: BG3 priority
; Bit 4: BG1 tile size (0=8x8, 1=16x16)
; Bit 5: BG2 tile size
; Bit 6: BG3 tile size
; Bit 7: BG4 tile size

BGMODE                      = $2105

; Example: Mode 1, 8x8 tiles
LDA #$01
STA BGMODE
```

**VRAM Access:**
```asm
; $2116/$2117: VMADDL/VMADDH - VRAM Address
; $2118/$2119: VMDATAL/VMDATAH - VRAM Data

VMADDL                      = $2116  ; VRAM address low
VMADDH                      = $2117  ; VRAM address high
VMDATAL                     = $2118  ; VRAM data low
VMDATAH                     = $2119  ; VRAM data high

; Example: Write to VRAM
LDA #$00                    ; VRAM address $0000
STA VMADDL
LDA #$00
STA VMADDH

LDA #$FF                    ; Write $FF to VRAM
STA VMDATAL
LDA #$00
STA VMDATAH
```

**DMA Registers:**

**DMA Setup:**
```asm
; $43X0: DMAPx - DMA Control
; Bits 0-2: Transfer mode
; Bit 3: Address adjustment (0=increment, 1=decrement)
; Bit 4: Unused
; Bit 5: Unused
; Bit 6: Unused
; Bit 7: Transfer direction (0=A->B, 1=B->A)

DMAP0                       = $4300  ; DMA channel 0
BBAD0                       = $4301  ; B-bus address
A1T0L                       = $4302  ; A-bus address low
A1T0H                       = $4303  ; A-bus address high
A1B0                        = $4304  ; A-bus bank
DAS0L                       = $4305  ; Transfer size low
DAS0H                       = $4306  ; Transfer size high

; Example: DMA graphics to VRAM
LDA #$01                    ; DMA mode 1 (2 registers write once)
STA DMAP0
LDA #$18                    ; Destination: $2118 (VMDATAL)
STA BBAD0
LDX #$8000                  ; Source: $7E8000
STX A1T0L
LDA #$7E                    ; Source bank
STA A1B0
LDX #$2000                  ; Size: 8KB
STX DAS0L

LDA #$01                    ; Start DMA on channel 0
STA $420B
```

---

### Code Standards

#### [`coding-standards.md`](coding-standards.md) 📋 Coding Standards
*Assembly code style guide and conventions*

**Contents:**
- Naming conventions
- Comment standards
- Code organization
- Indentation rules
- Best practices

**Use when:**
- Writing new code
- Reviewing code
- Maintaining consistency
- Contributing to project

**Naming Conventions:**

**Labels:**
```asm
; Functions: PascalCase
CalculateDamage:
    ; Function code
    RTS

; Local labels: dot-prefixed lowercase
.loop:
    ; Local code
    BNE .loop

; Constants: UPPER_SNAKE_CASE
MAX_HP = 9999
ITEM_CURE_POTION = $00

; Variables: CamelCase or snake_case
CurrentHP = $7E1000
current_mp = $7E1002
```

**Comments:**
```asm
; Function header comment
;-----------------------------------------------------------------------------
; CalculatePhysicalDamage
;
; Calculates damage for a physical attack
;
; Input:
;   A = Attacker index
;   X = Defender index
; Output:
;   A = Calculated damage (16-bit)
; Modifies:
;   A, X, Y, $00-$03
;-----------------------------------------------------------------------------
CalculatePhysicalDamage:
    ; Implementation
    RTS

; Inline comments: Explain WHY, not WHAT
LDA AttackerStats,X         ; Already obvious
LDA AttackerStats,X         ; Need attacker's base power (better)

; Group related code with section comments
    ; Calculate base damage
    LDA AttackerAttack
    ASL A                   ; Attack × 2
    SEC
    SBC DefenderDefense     ; - Defense
    
    ; Add variance
    JSR Random
    AND #$0F
    CLC
    ADC Damage
```

**Indentation:**
```asm
; Labels: No indentation
FunctionName:

; Instructions: 4 spaces
    LDA #$00
    STA $1234

; Local labels: 4 spaces + dot
.local_label:
    LDX #$00

; Instructions after local label: 8 spaces
        LDA Table,X
        STA Destination
```

---

### Label Documentation

#### [`LABEL_CONVENTIONS.md`](LABEL_CONVENTIONS.md) 🏷️ Label Conventions
*Label naming and usage conventions*

**Contents:**
- Label naming rules
- Namespace organization
- Special label types
- Label documentation requirements

**Use when:**
- Creating new labels
- Understanding existing labels
- Organizing code
- Writing documentation

---

#### [`LABEL_INDEX.md`](LABEL_INDEX.md) 📇 Label Index
*Complete index of all labels*

**Contents:**
- Alphabetical label list
- Label categories
- Cross-references
- Label usage examples

**Use when:**
- Finding label definitions
- Understanding label purposes
- Browsing available labels

---

#### [`LABEL_RENAME_MAPPING.md`](LABEL_RENAME_MAPPING.md) 🔄 Label Rename Map
*Mapping of old labels to new standardized names*

**Contents:**
- Old → new label mappings
- Rename rationale
- Affected code locations
- Migration guide

**Use when:**
- Understanding label history
- Updating old references
- Contributing to renaming effort

---

#### [`LABEL_CHANGELOG.md`](LABEL_CHANGELOG.md) 📝 Label Changelog
*History of label changes and additions*

**Contents:**
- Chronological label changes
- Addition dates
- Rename history
- Label deprecations

**Use when:**
- Tracking label evolution
- Understanding label history
- Reviewing changes

---

### Analysis Reports

#### [`UNREACHABLE_CODE_CATALOG.md`](UNREACHABLE_CODE_CATALOG.md) 🗂️ Unreachable Code
*Catalog of unreachable/unused code*

**Contents:**
- Identified unreachable code
- Potential dead code
- Unused functions
- Analysis methodology

**Use when:**
- Finding free space
- Understanding code coverage
- Cleaning up codebase

---

#### [`UNREACHABLE_CODE_REPORT.md`](UNREACHABLE_CODE_REPORT.md) 📊 Analysis Report
*Detailed unreachable code analysis*

**Contents:**
- Code reachability analysis
- Call graph analysis
- Unused code statistics
- Recommendations

**Use when:**
- Deep analysis needed
- Optimizing ROM space
- Understanding code organization

---

## Common Lookups

### Find Enemy Stats
```bash
# Look up enemy ID
grep "ENEMY_MINOTAUR" docs/reference/SYSTEM_CONSTANTS.md

# Get enemy structure
python tools/analysis/view_enemy.py --id 0x40
```

### Find Item ID
```bash
grep "ITEM_" docs/reference/SYSTEM_CONSTANTS.md | grep SWORD
```

### Look Up Memory Address
```bash
grep "Character" docs/reference/RAM_MAP.md
```

### Find Hardware Register
```bash
grep "VRAM" docs/reference/HARDWARE_REGISTER_STANDARDIZATION.md
```

---

## Data Structure Reference

Quick reference for common structures:

**Character:** 32 bytes (HP, MP, stats, equipment)  
**Enemy:** 16 bytes (HP, attack, defense, drops)  
**Item:** 8 bytes (type, power, price, flags)  
**Spell:** 12 bytes (MP cost, power, element)  
**Map Header:** 32 bytes (dimensions, tileset, music)

---

## Hardware Reference

Quick register reference:

**INIDISP ($2100):** Display control, brightness  
**BGMODE ($2105):** Background mode  
**VMADDR ($2116/7):** VRAM address  
**VMDATA ($2118/9):** VRAM data  
**DMAP ($43X0):** DMA control

---

## Related Documentation

- **[../architecture/](../architecture/)** - System architecture
- **[../battle/](../battle/)** - Battle system
- **[../graphics/](../graphics/)** - Graphics system
- **[../../src/](../../src/)** - Source code with labels

---

**Last Updated:** 2025-11-07  
**Specification Version:** 1.0
