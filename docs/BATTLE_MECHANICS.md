# Battle Mechanics Reference

Comprehensive documentation of Final Fantasy Mystic Quest battle mechanics, damage formulas, and action routines based on ROM analysis and FFMQ Randomizer battle simulator code.

## Table of Contents

- [Action Routines](#action-routines)
- [Damage Formulas](#damage-formulas)
- [Hit Rate Calculation](#hit-rate-calculation)
- [Defense Calculation](#defense-calculation)
- [Resistance & Weakness](#resistance--weakness)
- [Critical Hits](#critical-hits)
- [Status Effects](#status-effects)
- [Targeting Types](#targeting-types)
- [Examples](#examples)

---

## Action Routines

Every battle action uses one of these routines to determine damage calculation and behavior.

### Basic Attack Routines

| Routine | Description | Formula |
|---------|-------------|---------|
| **None** | No action (placeholder) | 0 damage |
| **Punch** | Bare-handed attack | `(Str + Spd) × 2` |
| **Sword** | Sword weapon attack | `(Str + Spd + Power) × 2` |
| **Axe** | Axe weapon attack (91% accuracy) | `(Str + Spd + Power) × 2` |
| **Claw** | Claw weapon attack | `(Str + Spd + Power) × 2` |
| **Bomb** | Bomb item attack | `Power × 12` |
| **Projectile** | Bow/thrown weapon attack | `(Spd × 2 + Power) × 2` |

### Magic Damage Routines

| Routine | Description | Formula |
|---------|-------------|---------|
| **MagicDamage1** | Basic magic (unused) | `(Mag + Power) × 3` |
| **MagicDamage2** | Standard spells (Cure, Fire, Blizzard, Thunder, Aero) | `(Mag + Power) × 3` |
| **MagicDamage3** | Powerful spells (Quake, White, Meteor, Flare) | `(Mag + Power) × 9` |
| **Life** | Resurrection spell | Revives KO'd ally, kills undead enemies |
| **Heal** | HP restoration | `(Mag × 1.5 + Power) × MaxHP / 100` |
| **Cure** | Status cure + damage undead | Same as Heal, damages undead |

### Physical Damage Routines

| Routine | Description | Formula | Hit Routine |
|---------|-------------|---------|-------------|
| **PhysicalDamage1** | Heavy physical (Bomb type) | `(Str + Power + MaxHP/16) × 2` | Speed |
| **PhysicalDamage2** | Standard physical | `(Str + Power + MaxHP/8) × 1.5` | Speed |
| **PhysicalDamage3** | Strength-based physical | `(Str + Power + MaxHP/8) × 1.5` | Strength |
| **PhysicalDamage4** | Elemental physical attacks | `(Str + Power + MaxHP/8) × 1.5` | Strength |
| **PhysicalDamage5** | Ailment-inflicting physical | `(Str + Power + MaxHP/8) × 0.75` | Strength |
| **PhysicalDamage6** | Confusion-inflicting attacks | `(Str + Power + MaxHP/8) × 0.75` | Str+Spd |
| **PhysicalDamage7** | Status-only attacks (50% hit) | 0 damage, applies ailment | Base |
| **PhysicalDamage8** | Multi-hit magic attacks | `(Str + Spd + Power) × Hits` | Magic |
| **PhysicalDamage9** | Drain HP attacks | `(Str + Power + MaxHP/8) × 0.75` | Plain |

**Boss Adjustments**: Bosses divide MaxHP by 2× (e.g., `/16` becomes `/160`, `/8` becomes `/80`)

### Special Routines

| Routine | Description | Behavior |
|---------|-------------|----------|
| **SelfDestruct** | Kamikaze attack | Damage = `User.MaxHP + Power`, user dies |
| **Multiply** | Create duplicate enemy | Spawns another enemy (90% hit) |
| **Seed** | Plant seed for later | Unused/unknown effect |
| **PureDamage1** | Fixed damage (no defense) | `Power × 8`, ignores modifiers |
| **PureDamage2** | Fixed damage variant | `Power × 8`, ignores modifiers |
| **Drain** | HP drain attack | `(Str + Power + MaxHP/8) × 0.75`, heals user |

---

## Damage Formulas

### Formula Components

**Attacker Stats**:
- `Str` (Attack): Physical attack power
- `Mag` (Magic): Magic attack power
- `Spd` (Speed): Speed stat
- `MaxHP`: Maximum HP (bosses use reduced divisor)

**Action Properties**:
- `Power`: Base power value from attack data
- `Hits`: Number of hits (for multi-hit attacks)

**Target Stats**:
- `Def` (Defense): Physical defense
- `MDef` (Magic Defense): Magic defense
- `Defending`: Boolean, doubles defense

### Physical Damage Calculation

```
Base Damage = (Formula from Action Routine)
             ÷ Target Count  (if Multi-target)
Final Damage = Apply Resistance/Weakness
             × Apply Critical Hit (2× if crit)
             - Defense (Physical actions only)
Minimum = 1 (unless immune)
```

**Example** (PhysicalDamage1):
```
User: Str=100, MaxHP=800, Action Power=20
Base = (100 + 20 + 800/16) × 2
     = (100 + 20 + 50) × 2  
     = 340

Target: Defense=40, Normal type
After Defense = 340 - 40 = 300 damage

If Critical Hit: 300 × 2 = 600 damage
```

### Magic Damage Calculation

```
Base Damage = (Mag + Power) × Multiplier
             ÷ Target Count  (if Multi-target)
Final Damage = Apply Resistance/Weakness
             × Apply Critical Hit (magic attacks cannot crit)
             - Magic Defense
Minimum = 1 (unless immune)
```

**Example** (MagicDamage3 - Flare):
```
User: Mag=50, Flare Power=200
Base = (50 + 200) × 9 = 2250

Target: MDef=30, Fire weakness
After Weakness = 2250 × 2 = 4500
After MDef = 4500 - 30 = 4470 damage
```

### Healing Calculation

```
Cure/Heal Formula:
Healing = ((Mag × 1.5 + Power) × MaxHP / 100) ÷ Target Count

Life Spell:
- Allies: Revive with full HP, remove all status
- Undead Enemies (if User.Level > Enemy.Level): Instant KO
```

**Example** (Cure):
```
Caster: Mag=40, Cure Power=0
Target: MaxHP=999

Healing = ((40 × 1.5 + 0) × 999 / 100)
        = (60 × 999 / 100)
        = 599 HP restored
```

---

## Hit Rate Calculation

Hit rate determines chance to hit target and chance for critical hit.

### Hit Routines

| Hit Routine | Hit Rate Formula | Critical Rate |
|-------------|------------------|---------------|
| **Plain** | 100% | 0% |
| **Hit100** | 100% | 0% |
| **Hit90** | 90% | 0% |
| **Base** | `Action.Accuracy / 2` | 0% |
| **Punch** | `((Str + Spd) / 8 + 0x4B + Accuracy) / 2` | 0% |
| **Sword** | `((Str + Spd) / 8 + 0x4B + Accuracy) / 2` | 5% |
| **Axe** | `((Str + Spd) / 8 + 0x4B + Accuracy) / 2` | 5% |
| **Claw** | `((Str + Spd) / 8 + 0x4B + Accuracy) / 2` | 5% |
| **Bomb** | `(Spd / 4 + 0x4B + Accuracy) / 2` | 0% |
| **Projectile** | `(Spd / 4 + 0x4B + Accuracy) / 2` | 5% |
| **Magic** | `(Mag / 4 + 0x4B + Accuracy) / 2` | 0% |
| **Speed** | `(Spd / 4 + 0x4B + Accuracy) / 2` | 5% |
| **Strength** | `(Str / 4 + 0x4B + Accuracy) / 2` | 5% |
| **StrengthSpeed** | `((Str + Spd) / 8 + 0x4B + Accuracy + User.Accuracy) / 2` | 0% |

**Constants**:
- `0x4B` = 75 (base hit rate boost)
- `Accuracy` = Action accuracy value (usually 100)

**Example**:
```
Sword Attack:
User: Str=80, Spd=60, Accuracy Stat=50
Action: Accuracy=100

Hit Rate = ((80 + 60) / 8 + 75 + 100 + 50) / 2
         = (17.5 + 75 + 100 + 50) / 2
         = 242.5 / 2 = 121 (capped at 100%)
Critical Rate = 5%
```

---

## Defense Calculation

### Physical Defense

```
Defense = Target.Defense
If Target is Defending:
    Defense = Max(Defense × 2, 250)
```

**Example**:
```
Normal:    Defense = 40
Defending: Defense = Max(40 × 2, 250) = 80
```

### Magic Defense

```
Defense = Target.MagicDefense
(Defending has no effect on magic defense)
```

---

## Resistance & Weakness

### Element Matching

Elements match if:
1. **Thunder Special Case**: Attack has Water AND Air → Target has Water AND Air
2. **Normal Case**: Any element in attack matches any in target resist/weakness list

**Element Types** (see `data/element_types.json`):
- Status: Silence, Blind, Poison, Confusion, Sleep, Paralysis, Stone, Doom
- Damage: Projectile, Bomb, Axe, Zombie
- Elements: Air, Fire, Water, Earth

### Resistance Calculation

```
If Attack elements match Target resistances:
    If Attack is Zombie type:
        Damage = -Damage  (healing becomes damage, damage becomes healing)
    Else:
        Damage = Damage / 2  (halve damage)
```

**Examples**:
```
1. Fire attack vs Salamander (Fire resist):
   Before: 1000 damage
   After:  500 damage

2. Zombie attack vs Skeleton (Zombie resist):
   Before: 200 damage
   After:  -200 (heals enemy by 200 HP)
   
   If healing spell: Cure 300 → becomes 300 damage!
```

### Weakness Calculation

```
If Attack elements match Target weaknesses:
    Damage = Damage × 2  (double damage)
```

**Example**:
```
Water attack vs Freeze Crab (Fire weakness):
Before: 800 damage
After:  1600 damage
```

### Order of Application

```
1. Calculate base damage
2. Divide by target count (multi-target)
3. Apply Resistance (÷2 or negate)
4. Apply Critical Hit (×2)
5. Apply Weakness (×2)
6. Subtract Defense
7. Cap at minimum 1 (or 0 if immune)
```

**Combined Example**:
```
Fire attack vs Ice enemy (Fire weakness):
Base: 1000 damage
Weakness: 1000 × 2 = 2000 damage
Defense: 2000 - 50 = 1950 final damage

Fire attack vs Salamander (Fire resist):  
Base: 1000 damage
Resistance: 1000 / 2 = 500 damage
Defense: 500 - 50 = 450 final damage
```

---

## Critical Hits

### Critical Hit Chance

Only physical weapon attacks can critical:
- **Sword**: 5% chance
- **Axe**: 5% chance
- **Claw**: 5% chance
- **Projectile**: 5% chance
- **Speed/Strength routines**: 5% chance
- **Magic attacks**: 0% chance (cannot critical)

### Critical Hit Effect

```
If Critical Hit occurs:
    Damage = Damage × 2
    Display "Critical Hit!" message
```

---

## Status Effects

### Status Application

Many attacks can inflict status ailments. See `data/element_types.json` for complete list.

**Common Ailments**:
- **Poison** (0x0004): Continuous damage over time
- **Blind** (0x0002): Reduced accuracy
- **Paralysis** (0x0020): Cannot act
- **Sleep** (0x0010): Cannot act until damaged
- **Confusion** (0x0008): Random target selection
- **Silence** (0x0001): Cannot use magic
- **Stone** (0x0040): Petrified, cannot act
- **Doom** (0x0080): KO countdown timer

### Application Mechanics

```
PhysicalDamage5-7 Actions:
    If Hit Roll succeeds:
        Apply ailments from action data
        
PhysicalDamage7 (Status Only):
    Hit Rate = Hit Rate / 2
    No damage dealt
    Only applies ailments if hit succeeds
```

---

## Targeting Types

### Single Target

| Type | Description |
|------|-------------|
| **SingleEnemy** | One enemy selected by player/AI |
| **SingleAlly** | One ally selected by player/AI |
| **SingleAny** | Any target (enemy or ally) |

### Multiple Target

| Type | Description |
|------|-------------|
| **MultipleEnemy** | All enemies, damage ÷ enemy count |
| **MultipleAlly** | All allies, healing ÷ ally count |
| **MultipleAny** | All targets in battle |

### Selection Target

| Type | Description |
|------|-------------|
| **SelectionEnemy** | Player selects which enemy |
| **SelectionAlly** | Player selects which ally |
| **SelectionAny** | Player selects any target |

**Multi-target Damage Division**:
```
Single Target: Full damage
Multi-target: Damage ÷ Target Count

Example:
Fire attack = 300 base damage
- Single Enemy: 300 damage
- 4 Enemies: 300 ÷ 4 = 75 damage each
```

---

## Examples

### Example 1: Basic Physical Attack

**Setup**:
- Benjamin attacks Brownie with Steel Sword
- Benjamin: Str=50, Spd=40, MaxHP=200
- Steel Sword: Power=10, Action=Sword
- Brownie: Defense=20

**Calculation**:
```
Action Routine: Sword
Formula: (Str + Spd + Power) × 2

Base Damage = (50 + 40 + 10) × 2 = 200

Hit Rate = ((50 + 40) / 8 + 75 + 100) / 2
         = (11.25 + 175) / 2
         = 93% hit, 5% critical

If Hit:
    Defense = 20
    Final = 200 - 20 = 180 damage
    
If Critical Hit:
    Damage = 180 × 2 = 360 damage
```

### Example 2: Elemental Magic Attack

**Setup**:
- Phoebe casts Blizzard on Salamander (Fire resist)
- Phoebe: Mag=60
- Blizzard: Power=10, MagicDamage2
- Salamander: MDef=15, Fire resistance

**Calculation**:
```
Action Routine: MagicDamage2
Formula: (Mag + Power) × 3

Base Damage = (60 + 10) × 3 = 210

Hit Rate = (60 / 4 + 75 + 100) / 2
         = 90% hit, 0% critical (magic cannot crit)

Salamander Resistances: Fire (0x2000)
Blizzard Elements: Water (0x4000)
Match: NO → No resistance modifier

Final = 210 - 15 (MDef) = 195 damage
```

### Example 3: Fire Weakness Exploitation

**Setup**:
- Benjamin casts Fire on Freeze Crab (Fire weakness)
- Benjamin: Mag=45
- Fire: Power=15, MagicDamage2, Fire element
- Freeze Crab: MDef=10, Fire weakness

**Calculation**:
```
Action Routine: MagicDamage2
Formula: (Mag + Power) × 3

Base Damage = (45 + 15) × 3 = 180

Freeze Crab Weaknesses: Fire (0x2000)
Fire Elements: Fire (0x2000)
Match: YES → Apply weakness

After Weakness = 180 × 2 = 360
Final = 360 - 10 (MDef) = 350 damage
```

### Example 4: Zombie Special Case

**Setup**:
- Skeleton attacks party with Zombie-type drain attack
- Party member with Zombie resistance
- Attack: Power=50, Zombie element

**Calculation**:
```
Normal target:
    Damage = 100
    Target takes 100 damage
    Attacker heals 100 HP

Zombie-resistant target:
    Damage = 100
    Resistance applies: 100 → -100 (reversed)
    Target HEALS 100 HP
    Attacker takes 100 damage (reversed drain)
    
This is why Zombie type is special!
```

### Example 5: Multi-Target Spell

**Setup**:
- Kaeli casts Quake (Multi-target)
- Kaeli: Mag=55
- Quake: Power=25, MagicDamage3, Earth element
- 4 Enemies: MDef=20 each

**Calculation**:
```
Action Routine: MagicDamage3
Formula: (Mag + Power) × 9

Base Damage = (55 + 25) × 9 = 720

Multi-target Division:
Per-Enemy Damage = 720 ÷ 4 = 180

Final per enemy = 180 - 20 (MDef) = 160 damage each

Total damage dealt: 160 × 4 = 640 damage
```

### Example 6: Self-Destruct

**Setup**:
- Grenade enemy uses Self-Destruct
- Grenade: MaxHP=150, Attack Power=50

**Calculation**:
```
Action Routine: SelfDestruct
Formula: User.MaxHP + Power

Damage = 150 + 50 = 200

Target Defense = 40
Final = 200 - 40 = 160 damage to target

Grenade HP = 0 (dies from self-destruct)
```

---

## Reference Data

### Action Routine IDs (from ROM)

Actions use these routine IDs (see `data/extracted/attacks/attacks.json`):

```
0x00: None
0x01: Punch
0x02: Sword  
0x03: Axe
0x04: Claw
0x05: Bomb
0x06: Projectile
0x07: MagicDamage1
0x08: MagicDamage2
0x09: MagicDamage3
0x0A: MagicStatsDebuff
0x0B: MagicUnknown2
0x0C: Life
0x0D: Heal
0x0E: Cure
0x0F: PhysicalDamage1
0x10: PhysicalDamage2
0x11: PhysicalDamage3
0x12: PhysicalDamage4
0x13: Ailments1
0x14: PhysicalDamage5
0x15: PhysicalDamage6
0x16: PhysicalDamage7
0x17: PhysicalDamage8
0x18: PhysicalDamage9
0x19: SelfDestruct
0x1A: Multiply
0x1B: Seed
0x1C: PureDamage1
0x1D: PureDamage2
```

### ROM Locations

**Attack Data**: Bank $02, $BC78 (7 bytes × 169 attacks)
```
Byte 0: Unknown1 (targeting?)
Byte 1: Unknown2
Byte 2: Power
Byte 3: Attack Type (Action Routine ID)
Byte 4: Attack Sound
Byte 5: Unknown3
Byte 6: Animation
```

**Enemy Stats**: Bank $02, $C275 (14 bytes × 83 enemies)
```
Byte 0-1: HP (little endian)
Byte 2: Attack
Byte 3: Defense
Byte 4: Speed
Byte 5: Magic
Byte 6-7: Resistances (16-bit bitfield)
Byte 8: Magic Defense
Byte 9: Magic Evade
Byte 10: Accuracy
Byte 11: Evade
Byte 12: Weaknesses (bitfield)
Byte 13: Unknown
```

**Element Types**: 16-bit bitfield (see `data/element_types.json`)

---

## Sources

This documentation is based on:

1. **ROM Analysis**: Direct examination of battle code in `src/asm/banks/bank_02.asm`
2. **FFMQ Randomizer**: Battle simulator implementation in `FFMQRLib/battlesim/`
   - Repository: https://github.com/wildham0/FFMQRando
   - Files: `BattleAction.cs`, `BattleSimulator.cs`, `Enums.cs`
3. **Extracted Data**: Enemy stats, attack data, element types from this project
4. **Testing**: In-game verification and damage calculations

**Last Updated**: 2025-11-02  
**ROM Version**: Final Fantasy Mystic Quest (NA v1.1)  
**MD5**: `f7faeae5a847c098d677070920769ca2`
