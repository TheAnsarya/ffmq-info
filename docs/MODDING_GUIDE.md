# Modding Guide - Final Fantasy Mystic Quest

A comprehensive guide to modifying and customizing Final Fantasy Mystic Quest using the disassembly project.

## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Quick Modifications](#quick-modifications)
- [Character Stats](#character-stats)
- [Dialogue and Text](#dialogue-and-text)
- [Graphics and Visuals](#graphics-and-visuals)
- [Items and Equipment](#items-and-equipment)
- [Spells and Abilities](#spells-and-abilities)
- [Maps and Levels](#maps-and-levels)
- [Common Pitfalls](#common-pitfalls)
- [Example Mods](#example-mods)

## Introduction

This guide will help you create your own modifications (mods) for Final Fantasy Mystic Quest. Whether you want to make the game harder, change the story, or create entirely new content, this guide has you covered.

**What You'll Learn:**
- How to modify character stats and progression
- How to edit dialogue and text
- How to replace graphics and sprites
- How to create new items and spells
- How to modify maps and encounters

**Prerequisites:**
- Completed [BUILD_GUIDE.md](BUILD_GUIDE.md) setup
- Basic understanding of hexadecimal numbers
- Text editor (VS Code recommended)
- Patience and willingness to experiment!

## Getting Started

### Setting Up Your Modding Environment

1. **Clone and build the project** (see [BUILD_GUIDE.md](BUILD_GUIDE.md))
2. **Create a mod branch** for your changes:
   ```bash
   git checkout -b my-awesome-mod
   ```
3. **Make a backup** of original ROM:
   ```bash
   cp ~roms/Final\ Fantasy\ -\ Mystic\ Quest\ \(U\)\ \(V1.1\).sfc backup/original.sfc
   ```

### Basic Workflow

```
1. Make changes to ASM/data files
2. Build ROM: .\build.ps1
3. Test in emulator
4. Iterate and refine
5. Document your changes
```

### Finding What to Modify

The disassembly is organized by ROM banks:

- `bank_00_documented.asm` - Core engine and initialization
- `bank_01_documented.asm` - Game engine code
- `bank_02_documented.asm` - Engine routines
- `bank_0B_documented.asm` - **Game logic and stats** ⭐
- `bank_0C_documented.asm` - **Menu system and UI** ⭐
- `bank_0D_documented.asm` - **Menu and UI** ⭐

**Most modding happens in banks $0B, $0C, and $0D!**

## Quick Modifications

### Make Benjamin Start at Level 10

**File**: `src/asm/bank_0B_documented.asm`

**Find** the character initialization data:
```asm
; Benjamin's starting stats
.db $01     ; Starting level
.db $14     ; Starting HP (20)
.db $0A     ; Starting MP (10)
```

**Change to**:
```asm
; Benjamin's starting stats  
.db $0A     ; Starting level (NOW LEVEL 10!)
.db $64     ; Starting HP (100)
.db $32     ; Starting MP (50)
```

**Build and test**: `.\build.ps1`

### Double All Enemy HP

**File**: `src/asm/bank_0B_documented.asm`

**Find** enemy stats table and multiply HP values by 2:
```asm
; Example: Behemoth
EnemyStats_Behemoth:
    .dw $0190   ; HP: 400 → Change to $0320 (800)
    .db $32     ; Attack
    .db $28     ; Defense
```

### Infinite MP Cheat

**File**: `src/asm/bank_01_documented.asm`

**Find** MP consumption code:
```asm
ConsumeMP:
    lda CurrentMP
    sec
    sbc SpellCost    ; Subtract MP cost
    sta CurrentMP
    rts
```

**Change to**:
```asm
ConsumeMP:
    ; Just return without subtracting!
    nop
    nop
    nop
    nop
    rts
```

## Character Stats

### Understanding Character Data

Character stats are stored as structured data:

```asm
CharacterData:
    .db Level       ; Current level (1-41)
    .db HP_Max      ; Maximum HP
    .db MP_Max      ; Maximum MP  
    .db Attack      ; Attack power
    .db Defense     ; Defense power
    .db Speed       ; Speed/Agility
    .db Magic       ; Magic power
    .db Accuracy    ; Hit rate
    .db Evasion     ; Dodge rate
```

### Modifying Starting Stats

**Location**: `bank_0B_documented.asm` - Character initialization tables

**Example**: Make Benjamin a tank with high HP and defense

```asm
; Original Benjamin stats
BenjaminStartStats:
    .db $01     ; Level 1
    .db $14     ; HP: 20
    .db $0A     ; MP: 10
    .db $08     ; Attack: 8
    .db $08     ; Defense: 8
    .db $08     ; Speed: 8
    .db $08     ; Magic: 8
    .db $64     ; Accuracy: 100
    .db $32     ; Evasion: 50

; Modified - TANK BUILD
BenjaminStartStats:
    .db $01     ; Level 1
    .db $32     ; HP: 50 (2.5x increase!)
    .db $05     ; MP: 5 (reduced)
    .db $0C     ; Attack: 12 (increased)
    .db $14     ; Defense: 20 (BIG increase!)
    .db $05     ; Speed: 5 (reduced)
    .db $04     ; Magic: 4 (reduced)
    .db $64     ; Accuracy: 100
    .db $1E     ; Evasion: 30 (reduced)
```

### Level-Up Growth Rates

**Location**: `bank_0B_documented.asm` - Level-up tables

```asm
; HP growth per level
BenjaminHPGrowth:
    .db $05     ; +5 HP per level (default)
    ; Change to $0A for +10 HP per level

; Attack growth per level  
BenjaminAttackGrowth:
    .db $02     ; +2 Attack per level
    ; Change to $04 for faster growth
```

### Example: Create a Magic-Focused Build

```asm
; Make Kaeli a powerful mage
KaeliStartStats:
    .db $05     ; Start at level 5
    .db $28     ; HP: 40
    .db $32     ; MP: 50 (HIGH!)
    .db $06     ; Attack: 6 (low)
    .db $08     ; Defense: 8
    .db $0C     ; Speed: 12 (good)
    .db $14     ; Magic: 20 (VERY HIGH!)
    .db $5A     ; Accuracy: 90
    .db $46     ; Evasion: 70
```

## Dialogue and Text

### Text Format

FFMQ uses a custom text encoding with control codes:

- `$00` - End of string
- `$01` - Newline
- `$02` - Wait for button press
- `$FE` - Character name placeholder

### Finding Dialogue

**Location**: Text is stored in various banks, often in `bank_0D`

### Simple Text Replacement

**Example**: Change the Bone Dungeon old man's dialogue

**Find** in `bank_0D_documented.asm`:
```asm
OldManText:
    .db "Go and defeat", $01
    .db "the Flamerus Rex!", $00
```

**Change to**:
```asm
OldManText:
    .db "The Flamerus Rex", $01
    .db "is super tough!", $00
```

**Important**: Keep text length similar to avoid overflow!

### Adding Your Own Dialogue

```asm
; New custom NPC dialogue
MyCustomNPC:
    .db "Welcome, brave", $01
    .db "adventurer!", $02     ; Wait for button
    .db "I have a quest", $01
    .db "for you...", $00      ; End
```

### Character Name in Dialogue

```asm
; Use $FE for player name
NPCGreeting:
    .db "Hello, ", $FE, "!", $01
    .db "How are you?", $00
```

### Common Pitfalls

❌ **Too Long**: Text overflow corrupts other data
```asm
.db "This text is way too long and will overflow the buffer!", $00
```

✅ **Just Right**: Keep it concise
```asm
.db "Keep it short!", $00
```

## Graphics and Visuals

### Graphics Organization

FFMQ graphics are stored as tiles:
- **4bpp format** (16 colors)
- **8x8 pixel tiles**
- Organized into character sets

### Extracting Graphics

```bash
# Extract all graphics to PNG
python tools/extract_graphics_v2.py ~roms/FFMQ.sfc

# Graphics saved to assets/graphics/
```

### Editing Graphics

1. **Extract graphics** using the Python tool
2. **Edit in image editor** (GIMP, Aseprite, Photoshop)
   - Keep 8x8 tile boundaries
   - Use only 16 colors per tile
   - Maintain palette
3. **Convert back** to SNES format
4. **Rebuild ROM**

### Example: Replace Benjamin's Sprite

```bash
# Extract Benjamin's character sprite
python tools/extract_graphics_v2.py ~roms/FFMQ.sfc --extract-character benjamin

# Edit assets/graphics/characters/benjamin.png
# (Use your favorite image editor)

# Convert back to SNES format
python tools/convert_graphics.py to-snes \
    assets/graphics/characters/benjamin_edited.png \
    assets/graphics/characters/benjamin.bin \
    --format 4bpp
```

### Palette Modification

**Location**: `bank_XX_documented.asm` - Palette data

```asm
; Example: Benjamin's palette
BenjaminPalette:
    .dw $0000   ; Color 0: Transparent
    .dw $7FFF   ; Color 1: White
    .dw $001F   ; Color 2: Red
    .dw $03E0   ; Color 3: Green
    ; ... more colors
```

**Color Format**: SNES 15-bit BGR (5 bits each)
- `$001F` = Red   (0, 0, 31)
- `$03E0` = Green (0, 31, 0)
- `$7C00` = Blue  (31, 0, 0)

### Example: Make Benjamin Blue

```asm
BenjaminPalette:
    .dw $0000   ; Transparent
    .dw $7FFF   ; White  
    .dw $7C00   ; Blue (was red!)
    .dw $5400   ; Dark blue (was green!)
```

## Items and Equipment

### Item Data Structure

```asm
ItemData:
    .db ItemID      ; Unique identifier
    .db Type        ; Weapon/Armor/Consumable
    .db AttackBonus ; Attack power bonus
    .db DefenseBonus; Defense bonus
    .db SpecialEffect; Special properties
    .dw Price       ; Cost in GP
```

### Creating a New Weapon

**Location**: `bank_0B_documented.asm` - Item tables

```asm
; Super Excalibur - Overpowered sword!
Item_SuperExcalibur:
    .db $FF     ; Item ID (use unused ID)
    .db $01     ; Type: Weapon
    .db $63     ; Attack: +99
    .db $00     ; Defense: +0
    .db $01     ; Special: Critical hit rate up
    .dw $9999   ; Price: 9999 GP

; Add item name to text table
ItemName_SuperExcalibur:
    .db "Super Excalibur", $00
```

### Modifying Existing Items

**Example**: Make Cure Potion restore full HP

```asm
; Original Cure Potion
Item_CurePotion:
    .db $01     ; Item ID
    .db $03     ; Type: Consumable
    .db $1E     ; Restore 30 HP

; Modified - FULL HEAL
Item_CurePotion:
    .db $01     ; Item ID
    .db $03     ; Type: Consumable
    .db $FF     ; Restore 255 HP (full heal!)
```

### Equipment Effects

```asm
; Armor with special effects
Item_DragonArmor:
    .db $20     ; Item ID
    .db $02     ; Type: Armor
    .db $00     ; Attack: +0
    .db $32     ; Defense: +50
    .db $04     ; Special: Fire resistance
    .dw $5000   ; Price: 5000 GP
```

**Special Effect Codes**:
- `$01` - Critical rate up
- `$02` - Poison immunity
- `$04` - Fire resistance
- `$08` - Ice resistance
- `$10` - Lightning resistance

## Spells and Abilities

### Spell Data Structure

```asm
SpellData:
    .db SpellID     ; Unique identifier
    .db MPCost      ; MP required
    .db Power       ; Base power/damage
    .db Element     ; Element type
    .db Target      ; Single/All/Self
    .db Animation   ; Visual effect ID
```

### Modifying Spell Power

**Example**: Make Cure spell stronger

```asm
; Original Cure
Spell_Cure:
    .db $01     ; Spell ID: Cure
    .db $04     ; MP cost: 4
    .db $1E     ; Power: 30 HP

; Modified - MEGA CURE
Spell_Cure:
    .db $01     ; Spell ID: Cure
    .db $04     ; MP cost: 4 (same)
    .db $63     ; Power: 99 HP (3x stronger!)
```

### Creating a New Spell

```asm
; Meteor - Ultimate attack spell
Spell_Meteor:
    .db $FF     ; Spell ID (unused)
    .db $63     ; MP cost: 99
    .db $FF     ; Power: 255 (MAXIMUM!)
    .db $00     ; Element: Non-elemental
    .db $01     ; Target: All enemies
    .db $0F     ; Animation: Meteor animation

; Add spell name
SpellName_Meteor:
    .db "Meteor", $00
```

### Element Types

```asm
Elements:
    $00 = Non-elemental
    $01 = Fire
    $02 = Ice
    $04 = Lightning
    $08 = Earth
```

## Maps and Levels

### Map Data

Maps consist of:
- **Tile layout** - Which tiles go where
- **Collision data** - Where you can/can't walk
- **Enemy encounters** - What enemies appear
- **NPC placement** - Where NPCs stand
- **Warp points** - Doors and transitions

### Modifying Enemy Encounters

**Location**: `bank_0B_documented.asm` - Encounter tables

```asm
; Forest area encounters
ForestEncounters:
    .db $05     ; 5% encounter rate
    .db $01     ; Enemy group 1
    .db $02     ; Enemy group 2
    .db $03     ; Enemy group 3

; Make encounters more frequent
ForestEncounters:
    .db $0F     ; 15% encounter rate (3x more!)
    .db $01     ; Enemy group 1
    .db $02     ; Enemy group 2
    .db $03     ; Enemy group 3
```

### Modifying Enemy Groups

```asm
; Original: 2 Goblins
EnemyGroup_01:
    .db $02     ; Number of enemies
    .db $01     ; Enemy type: Goblin
    .db $01     ; Enemy type: Goblin

; Modified: 5 Goblins!
EnemyGroup_01:
    .db $05     ; Number of enemies
    .db $01     ; Goblin
    .db $01     ; Goblin
    .db $01     ; Goblin
    .db $01     ; Goblin
    .db $01     ; Goblin
```

### Boss Modifications

```asm
; Make boss fights harder
Boss_DarkKing:
    .dw $03E8   ; HP: 1000 → Change to $07D0 (2000)
    .db $64     ; Attack: 100 → Change to $C8 (200)
    .db $32     ; Defense: 50 → Change to $64 (100)
```

## Common Pitfalls

### 1. Text Overflow

❌ **Wrong**:
```asm
NPCText:
    .db "This is way too much text that will overflow the buffer and corrupt other data!", $00
```

✅ **Right**:
```asm
NPCText:
    .db "Keep text", $01
    .db "concise!", $00
```

### 2. Invalid Values

❌ **Wrong**: Values too large
```asm
.db $999    ; ERROR: Byte can only hold 0-255!
```

✅ **Right**: Use appropriate size
```asm
.dw $0999   ; Word (16-bit) for larger values
.db $FF     ; Byte max is 255 ($FF)
```

### 3. Breaking Critical Code

❌ **Wrong**: Modifying unknown code
```asm
; Don't modify this unless you know what it does!
SomeFunction:
    lda $00
    sta $7E0000    ; Critical!
```

✅ **Right**: Modify data tables instead
```asm
; Safer to modify data
CharacterStats:
    .db $14     ; Safe to change!
```

### 4. Forgetting to Rebuild

Always rebuild after changes:
```powershell
.\build.ps1
```

### 5. Not Testing Changes

Test in emulator immediately:
```bash
mesen build/ffmq-rebuilt.sfc
```

### 6. Overwriting Critical Data

**Check file offsets!** Make sure your data doesn't overflow into other tables.

## Example Mods

### Example 1: "Hard Mode"

```asm
; Double all enemy stats
EnemyStats_Goblin:
    .dw $0028   ; HP: 40 → $0050 (80)
    .db $10     ; Attack: 16 → $20 (32)
    .db $08     ; Defense: 8 → $10 (16)

; Reduce cure effectiveness
Spell_Cure:
    .db $01     ; ID
    .db $08     ; MP cost: 8 (doubled!)
    .db $0F     ; Power: 15 (halved!)

; Reduce starting GP
StartingGP:
    .dw $0032   ; 50 GP (was 100)
```

### Example 2: "Easy Mode"

```asm
; Triple starting stats
BenjaminStartStats:
    .db $01     ; Level 1
    .db $3C     ; HP: 60 (was 20)
    .db $1E     ; MP: 30 (was 10)
    .db $18     ; Attack: 24 (was 8)
    .db $18     ; Defense: 24 (was 8)

; Cheap items
Item_CurePotion:
    .dw $0001   ; Price: 1 GP (was 10)

; No random encounters
ForestEncounters:
    .db $00     ; 0% encounter rate
```

### Example 3: "Randomizer"

```asm
; Randomize enemy stats (manually for now)
EnemyStats_Goblin:
    .dw $0064   ; HP: Random (100)
    .db $32     ; Attack: Random (50)
    .db $1E     ; Defense: Random (30)

EnemyStats_Dragon:
    .dw $0014   ; HP: Random (20) - weak!
    .db $08     ; Attack: Random (8)
    .db $05     ; Defense: Random (5)
```

### Example 4: "Color Randomizer"

```asm
; Randomize character palettes
BenjaminPalette:
    .dw $0000   ; Transparent
    .dw $7C1F   ; Purple (was white)
    .dw $03E0   ; Green (was red)
    .dw $7C00   ; Blue (was blue)

KaeliPalette:
    .dw $0000   ; Transparent
    .dw $001F   ; Red (was purple)
    .dw $7FE0   ; Yellow (was green)
    .dw $7FFF   ; White (was teal)
```

## Tips and Best Practices

### 1. Start Small

Begin with simple mods:
- Change a character's starting level
- Modify one item's stats
- Tweak one enemy's HP

### 2. Document Your Changes

Keep a log of what you modified:
```
# My Mod - Hard Mode
- Doubled all enemy HP
- Reduced cure spell effectiveness
- Increased encounter rates
```

### 3. Use Git Branches

```bash
# Create a branch for each mod
git checkout -b hard-mode
git checkout -b randomizer  
git checkout -b visual-overhaul
```

### 4. Test Incrementally

Test after EVERY change, not after 10 changes!

### 5. Backup Regularly

```bash
cp build/ffmq-rebuilt.sfc backups/my-mod-$(date +%Y%m%d).sfc
```

### 6. Learn by Doing

The best way to learn is to experiment. Don't be afraid to break things - you have backups!

### 7. Join the Community

- Share your mods
- Ask questions
- Learn from others
- Contribute improvements

## Advanced Topics

### Assembly Basics

Learn 65816 assembly for advanced mods:
- Understand opcodes and addressing modes
- Read and modify game logic
- Create new features

### Hex Editing

For quick tweaks without rebuilding:
```bash
# Edit ROM directly with hex editor
hexedit build/ffmq-rebuilt.sfc
```

### Scripting Your Mods

Create scripts to apply mods automatically:
```python
# apply_mod.py
def double_enemy_hp(asm_file):
    # Read file, find enemy stats, multiply HP
    pass
```

### ROM Hacking Tools

- **Lunar IPS** - Create and apply patches
- **YY-CHR** - Graphics editor
- **Mesen-S** - Debugger and memory viewer

## Resources

- **BUILD_GUIDE.md** - How to build the ROM
- **CONTRIBUTING.md** - Development guidelines
- **docs/ARCHITECTURE.md** - System architecture
- **ROM Hacking Discord** - Community support
- **GitHub Issues** - Report bugs, request features

## Conclusion

You now have the knowledge to create your own FFMQ mods! Remember:

✅ **Start simple**
✅ **Test frequently**  
✅ **Backup everything**
✅ **Have fun!**

The best mods come from experimentation and creativity. Don't be afraid to try new things!

Happy modding! 🎮✨

---

**Need Help?**
- Check [CONTRIBUTING.md](../CONTRIBUTING.md)
- Ask on Discord/IRC
- Open a GitHub issue
- Review existing mods for examples
