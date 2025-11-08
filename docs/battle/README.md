# Battle System Documentation

This directory contains comprehensive documentation for the Final Fantasy Mystic Quest battle system, including mechanics, data structures, enemy AI, damage calculations, and spell systems.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation Index](#documentation-index)
- [Battle System Architecture](#battle-system-architecture)
- [Common Tasks](#common-tasks)
- [Battle Mechanics Reference](#battle-mechanics-reference)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

---

## Overview

The FFMQ battle system is an action-based system with real-time elements combined with turn-based combat:

**Battle System Features:**
- **Real-time combat** - Enemies move and attack in real-time
- **Active Time Battle (ATB)** - Character actions based on speed/timers
- **Weapon system** - Swords, axes, bombs, claws with different mechanics
- **Magic system** - White, black, wizard spells
- **Enemy AI** - Pattern-based behavior with conditions
- **Status effects** - Poison, sleep, paralysis, etc.
- **Party system** - Up to 2 characters (Benjamin + companion)

**Battle Data Components:**
- Enemy stats and attributes
- Enemy AI scripts
- Spell data and effects
- Damage formulas
- Battle backgrounds
- Enemy formation tables
- Drop tables (items/gold/exp)

---

## Quick Start

### View Enemy Data

```bash
# Launch enemy editor GUI
python tools/battle/enemy_editor_gui.py

# View specific enemy stats
python tools/battle/view_enemy_stats.py --enemy-id 0x40  # Minotaur

# Export all enemy data
python tools/battle/export_enemy_data.py --output battle_data/enemies.json
```

### Edit Enemy Stats

```bash
# Edit enemy via GUI
python tools/battle/enemy_editor_gui.py --enemy-id 0x40

# Modify specific stat
python tools/battle/modify_enemy.py \
    --enemy-id 0x40 \
    --hp 2000 \
    --attack 150 \
    --defense 120

# Batch modify enemies
python tools/battle/batch_enemy_edit.py \
    --config config/enemy_changes.json
```

### Analyze Spell Data

```bash
# View spell stats
python tools/battle/spell_analyzer.py --spell-id 0x10  # Cure

# Export all spell data
python tools/battle/export_spell_data.py --output battle_data/spells.json

# Test damage calculations
python tools/battle/test_damage.py \
    --attacker-level 30 \
    --attacker-attack 100 \
    --defender-defense 80
```

---

## Documentation Index

### [`BATTLE_SYSTEM.md`](BATTLE_SYSTEM.md) ⚔️ **START HERE**
*Complete battle system architecture and overview*

**Contents:**
- Battle system architecture
- Combat flow and timing
- Battle initialization
- Turn processing
- Victory/defeat conditions
- Memory structures

**Use when:**
- Understanding battle system
- Modifying battle mechanics
- Debugging battle issues
- Implementing new features

**Battle System Architecture:**

**Core Components:**
```
1. Battle Initialization
   ↓
2. Enemy AI Processing
   ↓
3. Player Input Processing
   ↓
4. Action Resolution
   ↓
5. Damage Calculation
   ↓
6. Status Effect Updates
   ↓
7. Victory/Defeat Check
   ↓
8. Repeat from step 2
```

**Memory Layout (RAM):**
```
Battle State: $7E0100-$7E01FF
- Current HP (player, companion)
- Current MP
- Status effects
- Battle flags
- Turn counters

Enemy Data: $7E0200-$7E03FF
- Enemy HP (current)
- Enemy MP (current)
- Enemy status
- AI state
- Attack timers

Temporary Values: $7E0400-$7E04FF
- Damage calculations
- Random number storage
- Temporary flags
```

**Battle Flow:**

**Initialization (called when battle starts):**
```asm
InitBattle:
    JSR ClearBattleRAM      ; Clear battle memory
    JSR LoadEnemyData       ; Load enemy stats
    JSR LoadPlayerData      ; Load player/companion stats
    JSR InitializeAI        ; Set up enemy AI
    JSR LoadBattleBG        ; Load battle background
    JSR PlayBattleMusic     ; Start battle music
    JMP MainBattleLoop      ; Enter main loop
```

**Main Battle Loop:**
```asm
MainBattleLoop:
    JSR ProcessEnemyAI      ; Update enemy AI
    JSR ProcessPlayerInput  ; Check for player actions
    JSR UpdateTimers        ; Update ATB/action timers
    JSR ProcessActions      ; Execute pending actions
    JSR UpdateStatusEffects ; Update poison, regen, etc.
    JSR CheckVictory        ; Check if battle is won
    JSR CheckDefeat         ; Check if battle is lost
    JMP MainBattleLoop      ; Loop
```

**Action Processing:**
```asm
ProcessActions:
    ; Check if any actions pending
    LDA $7E0100             ; Battle flags
    AND #$01                ; Action pending?
    BEQ .done
    
    ; Process player action
    JSR ProcessPlayerAction
    
    ; Process enemy action
    JSR ProcessEnemyAction
    
    ; Update display
    JSR UpdateBattleDisplay
    
.done:
    RTS
```

---

### [`BATTLE_MECHANICS.md`](BATTLE_MECHANICS.md) 🎲 Battle Mechanics
*Detailed battle mechanics and formulas*

**Contents:**
- Damage calculation formulas
- Hit chance and evasion
- Critical hits
- Status effect mechanics
- Defense and mitigation
- Elemental system

**Use when:**
- Understanding damage calculations
- Balancing battles
- Implementing new mechanics
- Debugging damage values

**Damage Calculation:**

**Physical Damage Formula:**
```
Base Damage = (Attacker.Attack × 2) - Defender.Defense

Variance = Random(0, Base Damage / 16)

Final Damage = Base Damage + Variance

Minimum Damage = 1 (always deal at least 1 damage)
```

**Implementation (65816 assembly):**
```asm
CalculatePhysicalDamage:
    ; Load attacker's attack stat
    LDX AttackerIndex
    LDA BattleStats.Attack,X
    STA Temp.Attack
    
    ; Multiply by 2
    ASL A                   ; Attack × 2
    STA Temp.BaseDamage
    
    ; Load defender's defense
    LDX DefenderIndex
    LDA BattleStats.Defense,X
    STA Temp.Defense
    
    ; Subtract defense
    LDA Temp.BaseDamage
    SEC
    SBC Temp.Defense
    BCS .positive
    LDA #$0000              ; Clamp to 0 if negative
.positive:
    STA Temp.BaseDamage
    
    ; Calculate variance (base / 16)
    LSR A                   ; Divide by 16
    LSR A
    LSR A
    LSR A
    STA Temp.MaxVariance
    
    ; Get random variance
    JSR GetRandom
    AND Temp.MaxVariance    ; Random(0, variance)
    
    ; Add to base damage
    CLC
    ADC Temp.BaseDamage
    STA Temp.FinalDamage
    
    ; Ensure minimum 1 damage
    BNE .done
    INC A
.done:
    RTS
```

**Magical Damage Formula:**
```
Base Damage = (Caster.Magic × Spell.Power) / 16

Resistance = Defender.MagicDefense

Final Damage = Base Damage - (Base Damage × Resistance / 256)

Minimum Damage = 0 (can be fully resisted)
```

**Critical Hit System:**
```
Critical Chance = 1/16 (6.25%)

Critical Multiplier = 2.0

Critical Damage = Normal Damage × 2
```

**Implementation:**
```asm
CheckCritical:
    JSR GetRandom
    AND #$0F                ; Random(0, 15)
    BNE .not_critical
    
    ; Critical hit!
    LDA Temp.FinalDamage
    ASL A                   ; Damage × 2
    STA Temp.FinalDamage
    
    ; Set critical flag
    LDA #$01
    STA BattleFlags.Critical
    
.not_critical:
    RTS
```

**Hit Chance:**
```
Base Hit Chance = 95%

Miss Chance = 5% + (Defender.Agility / 256)

If Random(0, 255) < Miss Chance: Miss
Else: Hit
```

**Status Effect Duration:**
```
Duration = Base Duration + Random(0, 3) turns

Poison:    10-13 turns (2 HP per turn)
Sleep:     3-6 turns
Paralysis: 2-5 turns
Blind:     5-8 turns
```

**Elemental System:**

**Element Types:**
```
Elements:
- Fire
- Ice
- Thunder
- Earth

Weakness: 1.5× damage
Resistance: 0.5× damage
Immunity: 0× damage
```

**Element Calculation:**
```asm
ApplyElementalModifier:
    ; Check defender's element weakness
    LDA DefenderElemental
    AND AttackElement
    BEQ .check_resistance
    
    ; Weakness: damage × 1.5
    LDA Temp.Damage
    LSR A                   ; Damage / 2
    CLC
    ADC Temp.Damage         ; Damage + Damage/2 = 1.5×
    STA Temp.Damage
    RTS
    
.check_resistance:
    ; Check resistance
    LDA DefenderResist
    AND AttackElement
    BEQ .done
    
    ; Resistance: damage × 0.5
    LDA Temp.Damage
    LSR A                   ; Damage / 2
    STA Temp.Damage
    
.done:
    RTS
```

---

### [`BATTLE_DATA_PIPELINE.md`](BATTLE_DATA_PIPELINE.md) 🔄 Data Pipeline
*Battle data extraction and modification pipeline*

**Contents:**
- Data extraction workflows
- Data format specifications
- Modification procedures
- Re-insertion process
- Validation and testing

**Use when:**
- Extracting battle data
- Modifying enemy stats
- Adding new enemies
- Batch editing data

**Data Extraction Pipeline:**

**Step 1: Extract Enemy Data**
```bash
# Extract all enemy stats
python tools/battle/extract_enemy_data.py \
    --rom roms/ffmq.sfc \
    --output battle_data/enemies_raw.bin

# Convert to JSON for editing
python tools/battle/enemy_binary_to_json.py \
    --input battle_data/enemies_raw.bin \
    --output battle_data/enemies.json

# Output format:
{
  "enemies": [
    {
      "id": 0,
      "name": "Goblin",
      "hp": 50,
      "attack": 30,
      "defense": 20,
      "magic": 10,
      "magic_defense": 15,
      "agility": 25,
      "exp": 15,
      "gold": 10,
      "elemental_weakness": ["fire"],
      "elemental_resistance": [],
      "ai_script": "basic_melee",
      "drops": [
        {"item_id": 5, "chance": 128}  # 50% chance
      ]
    },
    ...
  ]
}
```

**Step 2: Edit Data**
```bash
# Option A: Edit JSON directly
notepad battle_data/enemies.json

# Option B: Use GUI editor
python tools/battle/enemy_editor_gui.py \
    --data battle_data/enemies.json

# Option C: Programmatic editing
python tools/battle/batch_modify.py \
    --input battle_data/enemies.json \
    --script modifications/buff_all_bosses.py \
    --output battle_data/enemies_modified.json
```

**Example modification script:**
```python
# modifications/buff_all_bosses.py
def modify_enemy(enemy):
    """Buff boss enemies."""
    if enemy['id'] >= 0x40:  # Boss IDs
        enemy['hp'] = int(enemy['hp'] * 1.5)
        enemy['attack'] = int(enemy['attack'] * 1.2)
        enemy['defense'] = int(enemy['defense'] * 1.2)
        enemy['exp'] = int(enemy['exp'] * 2.0)
        enemy['gold'] = int(enemy['gold'] * 2.0)
    return enemy
```

**Step 3: Validate Data**
```bash
# Validate enemy data
python tools/battle/validate_enemy_data.py \
    --input battle_data/enemies_modified.json

# Checks:
# - HP in valid range (1-9999)
# - Stats in valid range (0-255)
# - Valid item IDs in drop tables
# - Total drop chances <= 256
# - Valid AI script references
# - No duplicate enemy IDs
```

**Step 4: Convert Back to Binary**
```bash
# Convert JSON to binary format
python tools/battle/enemy_json_to_binary.py \
    --input battle_data/enemies_modified.json \
    --output battle_data/enemies_new.bin
```

**Step 5: Insert into ROM**
```bash
# Option A: Update source file
cp battle_data/enemies_new.bin src/data/enemy_stats.bin
# Then rebuild ROM

# Option B: Direct ROM insertion
python tools/rom-operations/insert_data.py \
    --rom build/ffmq.sfc \
    --address 0x123456 \
    --input battle_data/enemies_new.bin

# Option C: Use build system
python tools/build/build_rom.py --update-enemies
```

**Step 6: Test**
```bash
# Run battle tests
python tools/testing/test_battles.py \
    --rom build/ffmq.sfc \
    --enemy-id 0x40

# Check specific values
python tools/testing/verify_enemy_stats.py \
    --rom build/ffmq.sfc \
    --expected battle_data/enemies_modified.json
```

**Spell Data Pipeline:**

**Extract Spell Data:**
```bash
# Extract spell data
python tools/battle/extract_spell_data.py \
    --rom roms/ffmq.sfc \
    --output battle_data/spells.json

# Spell data format:
{
  "spells": [
    {
      "id": 0,
      "name": "Fire",
      "mp_cost": 4,
      "power": 30,
      "element": "fire",
      "target": "single",
      "animation_id": 5,
      "sound_effect": 12
    },
    ...
  ]
}
```

**Modify Spells:**
```python
# modifications/rebalance_spells.py
def modify_spell(spell):
    """Rebalance spell costs and power."""
    # Reduce MP costs
    spell['mp_cost'] = max(1, int(spell['mp_cost'] * 0.75))
    
    # Increase power slightly
    spell['power'] = int(spell['power'] * 1.1)
    
    return spell
```

---

### [`ENEMY_EDITOR_GUIDE.md`](ENEMY_EDITOR_GUIDE.md) 🛠️ Enemy Editor Guide
*Complete guide to using the enemy editor*

**Contents:**
- Enemy editor GUI usage
- Editing individual stats
- Batch editing
- AI script editing
- Testing modifications

**Use when:**
- Editing enemy stats
- Creating enemy variations
- Balancing battles
- Learning the editor

**Enemy Editor GUI:**

**Launching the Editor:**
```bash
# Launch with no enemy selected
python tools/battle/enemy_editor_gui.py

# Launch with specific enemy
python tools/battle/enemy_editor_gui.py --enemy-id 0x40

# Launch with custom data file
python tools/battle/enemy_editor_gui.py \
    --data battle_data/enemies_custom.json
```

**GUI Layout:**
```
┌─────────────────────────────────────────┐
│ Enemy Editor                             │
├─────────────────────────────────────────┤
│ Enemy List     │ Stats Editor            │
│ ┌──────────┐   │ Name: [Minotaur      ] │
│ │ Goblin   │   │ HP:   [1000          ] │
│ │ Snake    │   │ ATK:  [120           ] │
│ │ ...      │   │ DEF:  [80            ] │
│ │ Minotaur │◄──│ MAG:  [50            ] │
│ │ ...      │   │ MDF:  [60            ] │
│ └──────────┘   │ AGI:  [40            ] │
│                │                         │
│ ┌───────────────────────────────────┐   │
│ │ Elemental Properties              │   │
│ │ Weakness:   [X] Fire  [ ] Ice    │   │
│ │             [ ] Thunder [ ] Earth │   │
│ │ Resistance: [ ] Fire  [X] Ice    │   │
│ │             [ ] Thunder [ ] Earth │   │
│ └───────────────────────────────────┘   │
│                                          │
│ ┌───────────────────────────────────┐   │
│ │ Drops                              │   │
│ │ EXP:  [250]  Gold: [150]          │   │
│ │ Item: [Cure Potion v] Chance: 50% │   │
│ └───────────────────────────────────┘   │
│                                          │
│ ┌───────────────────────────────────┐   │
│ │ AI Script                          │   │
│ │ [Basic Melee          v]           │   │
│ │ [View Script...]                   │   │
│ └───────────────────────────────────┘   │
│                                          │
│ [Save] [Revert] [Export] [Test]        │
└─────────────────────────────────────────┘
```

**Editing Stats:**

**Numeric Stats:**
- Click in field or use arrow keys
- Type new value
- Valid ranges enforced automatically
- Press Enter to apply

**Valid Ranges:**
```
HP:            1 - 9999
Attack:        0 - 255
Defense:       0 - 255
Magic:         0 - 255
Magic Defense: 0 - 255
Agility:       0 - 255
EXP:           0 - 65535
Gold:          0 - 65535
```

**Elemental Properties:**
- Click checkboxes to toggle
- Can have multiple weaknesses/resistances
- Weakness and resistance are mutually exclusive per element

**Drop Tables:**
- Select item from dropdown
- Set drop chance (0-100%)
- Add multiple item drops
- Total chance can exceed 100% (independent rolls)

**Testing Modifications:**

**In-Editor Testing:**
```
1. Click "Test" button
2. Select test scenario:
   - Quick battle (vs. this enemy only)
   - In-game location (enemy in normal encounter)
3. Editor launches emulator with modified ROM
4. Play battle to test changes
5. Return to editor to refine
```

**Batch Editing:**
```bash
# Select multiple enemies in list (Ctrl+Click or Shift+Click)
# Right-click → Batch Edit

Batch Edit Dialog:
┌────────────────────────────────────┐
│ Batch Edit Selected Enemies        │
├────────────────────────────────────┤
│ Multiply HP by:     [1.5]          │
│ Multiply Attack by: [1.2]          │
│ Multiply Defense by:[1.2]          │
│ Add to EXP:         [50]           │
│ Add to Gold:        [25]           │
│                                    │
│ [Apply] [Cancel]                   │
└────────────────────────────────────┘
```

---

### [`SPELL_DATA_RESEARCH.md`](SPELL_DATA_RESEARCH.md) ✨ Spell Data Research
*Research notes on spell system*

**Contents:**
- Spell data structures
- Spell categories
- Effect implementations
- Animation system
- MP cost balancing

**Use when:**
- Understanding spell system
- Modifying spells
- Adding new spells
- Balancing magic

**Spell System Architecture:**

**Spell Categories:**

**White Magic (Healing/Support):**
```
Spell ID  Name        MP Cost  Power  Effect
--------  ----        -------  -----  ------
0x00      Cure        4        30     Heal single target
0x01      Cure2       8        60     Heal single target (stronger)
0x02      Cure3       12       120    Heal single target (strongest)
0x03      Life        8        50     Revive with 50% HP
0x04      Heal        6        Full   Remove poison/paralysis
0x05      Refresh     4        -      Restore status
```

**Black Magic (Offensive):**
```
Spell ID  Name        MP Cost  Power  Element  Effect
--------  ----        -------  -----  -------  ------
0x10      Fire        4        30     Fire     Single target damage
0x11      Fire2       8        60     Fire     All enemies damage
0x12      Ice         4        30     Ice      Single target damage
0x13      Ice2        8        60     Ice      All enemies damage
0x14      Thunder     4        35     Thunder  Single target damage
0x15      Thunder2    8        65     Thunder  All enemies damage
```

**Wizard Magic (Ultimate Spells):**
```
Spell ID  Name        MP Cost  Power  Element  Effect
--------  ----        -------  -----  -------  ------
0x20      Flare       16       150    Fire     Massive single damage
0x21      Blizzard    16       150    Ice      Massive single damage
0x22      Mega        20       200    -        Ultimate non-elemental
0x23      White       24       250    Holy     Holy damage all enemies
```

**Spell Data Structure:**

**Binary Format (12 bytes per spell):**
```
Offset  Size  Description
------  ----  -----------
0x00    1     Spell ID
0x01    1     MP Cost
0x02    2     Power (16-bit, little-endian)
0x04    1     Element (bit flags)
0x05    1     Target (0=single, 1=all enemies, 2=all allies)
0x06    1     Animation ID
0x07    1     Sound Effect ID
0x08    2     Spell Flags (various properties)
0x0A    2     Reserved/Padding
```

**Element Bit Flags:**
```
Bit 0: Fire
Bit 1: Ice
Bit 2: Thunder
Bit 3: Earth
Bit 4: Holy
Bit 5: Dark
Bit 6-7: Unused
```

**Spell Damage Calculation:**
```asm
CalculateSpellDamage:
    ; Base = (Caster.Magic × Spell.Power) / 16
    LDA CasterMagic
    STA Math.MultA
    LDA SpellPower
    STA Math.MultB
    JSR Multiply16bit      ; Result in Math.Product
    
    LDA Math.Product+1     ; Get high byte (divide by 16)
    LSR A
    LSR A
    LSR A
    LSR A
    STA Temp.BaseDamage
    
    LDA Math.Product
    AND #$F0
    ORA Temp.BaseDamage
    STA Temp.BaseDamage
    
    ; Apply target's magic defense
    LDA TargetMagicDef
    STA Temp.Resistance
    
    ; Damage = Base - (Base × Resistance / 256)
    LDA Temp.BaseDamage
    STA Math.MultA
    LDA Temp.Resistance
    STA Math.MultB
    JSR Multiply16bit
    
    LDA Math.Product+1     ; High byte = (Base × Res) / 256
    STA Temp.Reduction
    
    LDA Temp.BaseDamage
    SEC
    SBC Temp.Reduction
    STA Temp.FinalDamage
    
    RTS
```

**MP Cost Balancing:**

**Design Principles:**
```
Single-target spells: Lower cost
All-target spells: ~2× single cost
Tier 2 spells: ~2× Tier 1 cost
Tier 3 spells: ~3× Tier 1 cost

Healing vs Damage:
- Healing costs similar to damage
- Life (revive) costs premium
- Status cure cheaper than damage
```

**Recommended Costs:**
```
Low-level (early game): 3-5 MP
Mid-level: 6-10 MP
High-level: 12-16 MP
Ultimate: 18-24 MP

Max MP typically: 999
Average MP at end-game: ~400
```

---

## Battle System Architecture

### Core Systems

**1. Battle Initialization:**
```asm
InitBattle:
    ; Clear battle RAM
    LDX #$0200
    LDA #$00
.clear_loop:
    STA $7E0100,X
    DEX
    BNE .clear_loop
    
    ; Load enemy data
    JSR LoadEnemyFormation
    
    ; Initialize player data
    JSR LoadPartyData
    
    ; Set up AI
    JSR InitializeAI
    
    ; Load graphics
    JSR LoadBattleGraphics
    
    ; Start music
    JSR PlayBattleTheme
    
    RTS
```

**2. Turn Processing:**
```asm
ProcessTurn:
    ; Check ATB timers
    JSR UpdateATB
    
    ; Process ready actions
    JSR ProcessReadyActions
    
    ; Update status effects
    JSR UpdateStatusEffects
    
    ; Check for battle end
    JSR CheckBattleEnd
    
    RTS
```

**3. Action Resolution:**
```asm
ResolveAction:
    ; Determine action type
    LDA ActionType
    CMP #$00                ; Attack
    BEQ .attack
    CMP #$01                ; Spell
    BEQ .spell
    CMP #$02                ; Item
    BEQ .item
    CMP #$03                ; Defend
    BEQ .defend
    
.attack:
    JSR ProcessAttack
    RTS
    
.spell:
    JSR ProcessSpell
    RTS
    
.item:
    JSR ProcessItem
    RTS
    
.defend:
    JSR ProcessDefend
    RTS
```

**4. Damage Application:**
```asm
ApplyDamage:
    ; Get target current HP
    LDX TargetIndex
    LDA CurrentHP,X
    STA Temp.OldHP
    
    ; Subtract damage
    SEC
    SBC DamageAmount
    BCS .no_underflow
    LDA #$0000              ; Clamp to 0
.no_underflow:
    STA CurrentHP,X
    
    ; Check for death
    BNE .alive
    JSR ProcessDeath
    
.alive:
    ; Update HP display
    JSR UpdateHPDisplay
    
    RTS
```

---

## Common Tasks

### View Enemy Stats
```bash
python tools/battle/view_enemy_stats.py --enemy-id 0x40
```

### Modify Enemy HP
```bash
python tools/battle/modify_enemy.py --enemy-id 0x40 --hp 2000
```

### Export All Battle Data
```bash
python tools/battle/export_all_battle_data.py --output battle_data/
```

### Test Damage Calculation
```bash
python tools/battle/test_damage.py \
    --attacker-attack 100 \
    --defender-defense 50 \
    --show-formula
```

### Create Enemy Variation
```bash
# Copy enemy and modify
python tools/battle/clone_enemy.py \
    --source 0x40 \
    --target 0x60 \
    --name "Dark Minotaur" \
    --hp-multiplier 1.5 \
    --attack-multiplier 1.3
```

---

## Battle Mechanics Reference

### Damage Formula
```
Physical Damage = (Attack × 2) - Defense + Random(0, Attack/16)
Magical Damage = (Magic × Power / 16) - (Base × MagicDef / 256)
Critical Damage = Normal Damage × 2
```

### Hit Chance
```
Base Hit = 95%
Miss Chance = 5% + (Agility / 256)
```

### Status Effects
- **Poison:** 2 HP/turn for 10-13 turns
- **Regen:** 5% max HP/turn for 10-13 turns
- **Sleep:** Cannot act for 3-6 turns
- **Paralysis:** 50% miss chance for 2-5 turns

### EXP/Gold Calculation
```
EXP Gained = Enemy.EXP × (1 + LevelDifference / 10)
Gold Gained = Enemy.Gold × Random(0.8, 1.2)
```

---

## Troubleshooting

### Enemy Stats Not Applying

**Problem:** Modified enemy stats don't appear in-game

**Solutions:**
1. Verify data was inserted correctly
2. Check if data is compressed (decompress first)
3. Ensure correct ROM address
4. Rebuild ROM completely
5. Clear emulator save states

### Damage Calculations Incorrect

**Problem:** Damage doesn't match expected values

**Solutions:**
1. Check formula implementation
2. Verify stats are loaded correctly
3. Account for status effects
4. Check for integer overflow
5. Verify critical hit detection

### Battle Crashes

**Problem:** Game crashes when entering battle

**Solutions:**
1. Check enemy formation table integrity
2. Verify enemy IDs are valid
3. Check AI script references
4. Verify battle background IDs
5. Check for RAM corruption

---

## Related Documentation

### Within This Directory
- **[BATTLE_SYSTEM.md](BATTLE_SYSTEM.md)** - Battle system architecture
- **[BATTLE_MECHANICS.md](BATTLE_MECHANICS.md)** - Detailed mechanics
- **[BATTLE_DATA_PIPELINE.md](BATTLE_DATA_PIPELINE.md)** - Data workflows
- **[ENEMY_EDITOR_GUIDE.md](ENEMY_EDITOR_GUIDE.md)** - Editor guide
- **[SPELL_DATA_RESEARCH.md](SPELL_DATA_RESEARCH.md)** - Spell system

### Other Documentation
- **[../../tools/battle/README.md](../../tools/battle/README.md)** - Battle tools
- **[../reference/DATA_STRUCTURES.md](../reference/DATA_STRUCTURES.md)** - Data structures
- **[../architecture/ARCHITECTURE.md](../architecture/ARCHITECTURE.md)** - System architecture

---

**Last Updated:** 2025-11-07  
**Battle System Version:** Original FFMQ
