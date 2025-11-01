# Battle System Architecture

Complete documentation of the Final Fantasy Mystic Quest battle system mechanics and implementation.

## Table of Contents

- [System Overview](#system-overview)
- [Battle Flow](#battle-flow)
- [Turn System](#turn-system)
- [Damage Calculation](#damage-calculation)
- [Status Effects](#status-effects)
- [Enemy AI](#enemy-ai)
- [Battle Commands](#battle-commands)
- [Experience and Leveling](#experience-and-leveling)
- [Battle Rewards](#battle-rewards)
- [Code Locations](#code-locations)

## System Overview

FFMQ uses an Active Time Battle (ATB) system with unique mechanics:

- **Real-time combat** with ATB gauges
- **Up to 3 party members** (Benjamin + 2 allies)
- **Up to 8 enemies** simultaneously
- **4 action commands** per character (Attack, Magic, Defend, Item)
- **Elemental weaknesses** and resistances
- **Status effects** (Poison, Sleep, Paralyze, etc.)

### Battle Structure

```
┌─────────────────────────┐
│   Battle Initialization │
├─────────────────────────┤
│ - Load enemy data       │
│ - Setup battle screen   │
│ - Initialize ATB gauges │
│ - Play battle music     │
└───────────┬─────────────┘
            │
            v
┌─────────────────────────┐
│    Main Battle Loop     │
├─────────────────────────┤
│ - Update ATB gauges     │
│ - Process AI decisions  │
│ - Handle player input   │
│ - Execute actions       │
│ - Check win/lose        │
└───────────┬─────────────┘
            │
            v
┌─────────────────────────┐
│    Battle Resolution    │
├─────────────────────────┤
│ - Award EXP/GP          │
│ - Item drops            │
│ - Level up check        │
│ - Return to field       │
└─────────────────────────┘
```

## Battle Flow

### Battle Initialization

```
1. Encounter Triggered
   ↓
2. Fade Screen
   ↓
3. Load Battle Background
   ↓
4. Load Enemy Graphics
   ↓
5. Initialize Enemy Stats
   │
   ├─ HP/MP values
   ├─ Attack/Defense
   ├─ Elemental resistances
   └─ AI behavior flags
   ↓
6. Position Enemies
   ↓
7. Initialize Party Status
   │
   ├─ Current HP/MP
   ├─ Equipment bonuses
   └─ Active status effects
   ↓
8. Reset ATB Gauges (all = 0)
   ↓
9. Play Battle Music
   ↓
10. Begin Battle Loop
```

**Code Location**: `bank_0B.asm` - `InitializeBattle`

### Main Battle Loop

```
Each Frame (60 Hz):

1. Update ATB Gauges
   │
   ├─ Party members: +Speed
   └─ Enemies: +Agility
   ↓
2. Check Full Gauges
   │
   ├─ Party member ready → Show command menu
   └─ Enemy ready → Execute AI decision
   ↓
3. Process Active Actions
   │
   ├─ Animations
   ├─ Damage calculation
   ├─ Status effects
   └─ Sound effects
   ↓
4. Update Display
   │
   ├─ HP/MP bars
   ├─ Damage numbers
   └─ Status icons
   ↓
5. Check Battle End
   │
   ├─ All enemies defeated → Victory
   ├─ All party KO'd → Game Over
   └─ Escape successful → End battle
   ↓
6. Repeat if battle continues
```

**Code Location**: `bank_0B.asm` - `BattleMainLoop`

## Turn System

### ATB (Active Time Battle)

Each combatant has an ATB gauge that fills over time:

```
ATB Gauge: 0 ──────────────► 255 (Full)

Fill Rate = Base Speed × Speed Multiplier

Base Speed:
- Party: Character's Speed stat (8-99)
- Enemies: Enemy's Agility stat (10-255)

Speed Multipliers:
- Normal: 1.0×
- Haste: 2.0×
- Slow: 0.5×
- Paralyzed: 0.0× (frozen)
```

### Turn Order

```asm
; ==============================================================================
; UpdateATBGauges - Update all ATB gauges
; ==============================================================================
UpdateATBGauges:
    ; Update party member gauges
    ldx #$00                ; Start with Benjamin
.partyLoop:
    lda PartyStatus,x       ; Check if alive
    bmi .nextParty          ; Skip if KO'd
    
    lda PartyATB,x          ; Get current ATB
    clc
    adc PartySpeed,x        ; Add speed stat
    sta PartyATB,x          ; Save new ATB
    
    cmp #$ff                ; Check if full
    bcc .nextParty
    
    ; ATB full - enable action
    lda #$ff
    sta PartyATB,x
    lda #$01
    sta PartyActionReady,x
    
.nextParty:
    inx
    cpx #$03                ; 3 party members
    bcc .partyLoop
    
    ; Update enemy gauges (similar logic)
    ldx #$00
.enemyLoop:
    ; ... similar code for enemies ...
    inx
    cpx #$08                ; Up to 8 enemies
    bcc .enemyLoop
    
    rts
```

### Action Execution

When ATB gauge is full:

```
Party Member Turn:
  1. ATB gauge full
  2. Display command menu
  3. Player selects action
  4. Execute action
  5. Reset ATB to 0
  6. Start filling again

Enemy Turn:
  1. ATB gauge full
  2. AI selects action
  3. Execute action immediately
  4. Reset ATB to 0
  5. Start filling again
```

## Damage Calculation

### Physical Damage Formula

```
Base Damage = (Attacker.Attack - Target.Defense) × 2

Random Variance = Base × (224-255) / 256  (≈88-100%)

Critical Hit = Base × 2  (5% chance)

Final Damage = Apply Modifiers:
  - Elemental weakness: ×2
  - Elemental resistance: ×0.5
  - Elemental immunity: 0
  - Defending: ×0.5
  - Back attack: ×1.5

Minimum Damage = 1 (unless immune)
```

### Magic Damage Formula

```
Base Damage = Spell.Power + (Caster.Magic / 4)

Random Variance = Base × (224-255) / 256

Elemental Modifier:
  - Weakness: ×2
  - Resistance: ×0.5
  - Immunity: 0

Final Damage = Base × Elemental Modifier

Healing = Base (no variance or modifiers)
```

### Code Example

```asm
; ==============================================================================
; CalculatePhysicalDamage - Calculate attack damage
; ==============================================================================
; Inputs:
;   $00 = Attacker index
;   $01 = Target index
; Outputs:
;   $02-$03 = Damage value
; ==============================================================================
CalculatePhysicalDamage:
    ; Get attacker's attack stat
    ldx $00
    lda CharacterAttack,x
    sta $10
    
    ; Get target's defense stat
    ldx $01
    lda EnemyDefense,x
    sta $11
    
    ; Base damage = (Attack - Defense) × 2
    lda $10
    sec
    sbc $11                 ; Attack - Defense
    bmi .minDamage          ; Negative? Set minimum
    
    asl a                   ; × 2
    sta $12                 ; Save base damage
    
    ; Random variance (88-100%)
    jsr Random              ; A = random 0-255
    and #$1f                ; Limit to 0-31
    clc
    adc #224                ; Add 224 = range 224-255
    sta $13
    
    ; Multiply: Damage = Base × Variance / 256
    lda $12
    jsr Multiply8x8         ; A × $13 → $14-$15
    lda $15                 ; High byte = result
    sta $02
    
    ; Check for critical hit (5% chance)
    jsr Random
    cmp #$0d                ; 13/256 ≈ 5%
    bcs .noCritical
    
    ; Critical! Double damage
    lda $02
    asl a
    sta $02
    
.noCritical:
    ; Apply elemental modifiers
    jsr ApplyElementalModifier
    
    ; Ensure minimum damage
    lda $02
    bne .done
.minDamage:
    lda #$01
    sta $02
    
.done:
    rts
```

### Damage Display

Damage numbers appear as sprites above targets:

```
Damage < 100:   Normal size, white
Damage 100-999: Large size, yellow
Damage 1000+:   Huge size, red (9999 cap)
Critical:       Yellow with "!" mark
Miss:           "MISS" text
```

## Status Effects

### Status Effect Types

```
Status      Effect                          Duration
──────────────────────────────────────────────────────
Poison      HP drain each turn (-HP/16)    Until cured
Sleep       Cannot act, gauge frozen        3-5 turns
Paralyze    Cannot act, gauge frozen        2-4 turns
Confusion   Random targets/actions          3-5 turns
Blind       50% miss rate                   5-7 turns
Silence     Cannot cast magic               5-7 turns
Petrify     Turned to stone (KO)            Permanent
Doom        Countdown to KO                 10 turns
Regen       HP restore each turn (+HP/8)    5 turns
Haste       ATB fills 2× faster             5 turns
Slow        ATB fills 0.5× slower           5 turns
Protect     Defense +50%                    5 turns
Shell       Magic defense +50%              5 turns
```

### Status Processing

```asm
; ==============================================================================
; ProcessStatusEffects - Apply status effects each turn
; ==============================================================================
ProcessStatusEffects:
    ldx #$00                ; Character index
.loop:
    lda CharacterStatus,x
    beq .next               ; No status? Skip
    
    ; Check poison
    bit #$01
    beq .checkRegen
    jsr ApplyPoison         ; Damage HP
    
.checkRegen:
    bit #$02
    beq .checkDoom
    jsr ApplyRegen          ; Restore HP
    
.checkDoom:
    bit #$80
    beq .decrementDuration
    dec DoomCounter,x       ; Countdown
    bne .decrementDuration
    jsr KnockOut            ; Timer = 0 → KO
    
.decrementDuration:
    ; Decrement status effect timers
    lda StatusDuration,x
    beq .next
    dec StatusDuration,x
    bne .next
    
    ; Duration = 0, remove status
    lda #$00
    sta CharacterStatus,x
    
.next:
    inx
    cpx #$03                ; 3 party members
    bcc .loop
    
    rts
```

### Status Resistance

Enemies can have status immunities:

```
Resistance Flags (16-bit):
  Bit 0:  Poison immunity
  Bit 1:  Sleep immunity
  Bit 2:  Paralyze immunity
  Bit 3:  Confusion immunity
  Bit 4:  Blind immunity
  Bit 5:  Silence immunity
  Bit 6:  Petrify immunity
  Bit 7:  Doom immunity
  Bit 8:  All status immunity (boss flag)
```

## Enemy AI

### AI Behavior Patterns

FFMQ enemies use pattern-based AI:

```
AI Pattern Types:
  1. Simple - Random physical attack
  2. Magic User - Prefers spells over attacks
  3. Healer - Heals allies when HP low
  4. Conditional - Changes based on HP/MP
  5. Counter - Responds to specific actions
  6. Boss - Complex multi-phase behavior
```

### AI Decision Tree

```
Enemy Turn Start
   ↓
Check HP Threshold
   │
   ├─ HP < 25% → Use desperate move
   ├─ HP < 50% → Defensive/healing
   └─ HP > 50% → Normal pattern
   ↓
Check MP
   │
   ├─ MP > 0 → Can use magic
   └─ MP = 0 → Physical only
   ↓
Select Action from Pattern
   │
   ├─ Physical attack (60%)
   ├─ Magic spell (30%)
   └─ Special ability (10%)
   ↓
Select Target
   │
   ├─ Lowest HP party member
   ├─ Random party member
   └─ All party members (AoE)
   ↓
Execute Action
```

### AI Code Example

```asm
; ==============================================================================
; EnemyAI - Determine enemy action
; ==============================================================================
; Inputs:
;   X = Enemy index
; Outputs:
;   $00 = Action ID
;   $01 = Target index
; ==============================================================================
EnemyAI:
    ; Get enemy AI pattern
    lda EnemyAIPattern,x
    asl a                   ; × 2 (word table)
    tax
    lda AIPatternTable,x
    sta $10
    lda AIPatternTable+1,x
    sta $11
    
    ; Jump to pattern handler
    jmp ($10)
    
; Simple AI - Random attack
AIPattern_Simple:
    ; 80% attack, 20% defend
    jsr Random
    cmp #$33                ; 51/256 ≈ 20%
    bcs .attack
    
    lda #$02                ; Defend command
    sta $00
    rts
    
.attack:
    lda #$00                ; Attack command
    sta $00
    jsr SelectRandomTarget
    sta $01
    rts
    
; Magic User AI
AIPattern_MagicUser:
    ; Check MP
    lda EnemyMP,x
    beq AIPattern_Simple    ; No MP? Use simple
    
    ; 70% magic, 30% attack
    jsr Random
    cmp #$4d                ; 77/256 ≈ 30%
    bcs .magic
    
    lda #$00                ; Attack
    sta $00
    jsr SelectRandomTarget
    sta $01
    rts
    
.magic:
    ; Select spell based on situation
    jsr SelectBestSpell
    sta $00
    jsr SelectSpellTarget
    sta $01
    rts
```

### Boss AI

Boss enemies use multi-phase AI:

```
Phase 1 (HP > 66%):
  - Normal attack pattern
  - Occasional special move
  
Phase 2 (HP 33-66%):
  - Increased attack frequency
  - Uses more powerful spells
  - May summon minions
  
Phase 3 (HP < 33%):
  - Desperate mode
  - Ultimate attacks unlocked
  - May use self-buff spells
  - Faster ATB gauge
```

## Battle Commands

### Command Structure

Each character has 4 command slots:

```
Slot 0: Attack  - Physical attack on single enemy
Slot 1: Magic   - Cast spell (MP cost)
Slot 2: Defend  - Reduce damage to 50% until next turn
Slot 3: Item    - Use consumable item
```

### Attack Command

```asm
; ==============================================================================
; ExecuteAttack - Perform physical attack
; ==============================================================================
; Inputs:
;   $00 = Attacker index
;   $01 = Target index
; ==============================================================================
ExecuteAttack:
    ; Play attack animation
    jsr PlayAttackAnimation
    
    ; Calculate damage
    jsr CalculatePhysicalDamage
    
    ; Check for miss
    jsr CheckHitRate
    bcc .miss
    
    ; Apply damage
    ldx $01                 ; Target index
    lda EnemyHP,x
    sec
    sbc $02                 ; Subtract damage
    bcs .notKO
    lda #$00                ; HP can't go negative
.notKO:
    sta EnemyHP,x
    
    ; Display damage number
    jsr DisplayDamage
    
    ; Check if target KO'd
    lda EnemyHP,x
    bne .done
    jsr EnemyDefeated
    
.done:
    rts
    
.miss:
    jsr DisplayMiss
    rts
```

### Magic Command

```
Magic Menu Flow:
  1. Open spell list
  2. Display available spells
  3. Show MP costs
  4. Player selects spell
  5. Check if enough MP
  6. Select target(s)
  7. Consume MP
  8. Execute spell
  9. Apply effects
```

### Defend Command

```
Effects of Defending:
- Damage received × 0.5
- ATB gauge still fills
- Status effects still apply
- Lasts until next action
- No MP/item cost
```

### Item Command

```
Item Menu:
  - Potion: Restore HP
  - Ether: Restore MP
  - Elixir: Full HP/MP restore
  - Antidote: Cure poison
  - Eye Drops: Cure blind
  - etc.

Item Use:
  1. Select item from inventory
  2. Select target
  3. Consume item (quantity -1)
  4. Apply effect immediately
  5. No turn delay
```

## Experience and Leveling

### EXP Calculation

```
EXP Awarded = Enemy.BaseEXP × Multiplier

Multipliers:
  - Overkill (damage > HP × 2): ×1.5
  - All enemies defeated: ×1.2
  - Quick victory (< 10 turns): ×1.1
  - No damage taken: ×1.2
  
Maximum multiplier: ×2.0 (stacks)
```

### Level Up Formula

```
EXP Required for Level N:
  EXP(N) = 100 × N² + 50 × N

Example:
  Level 2: 100×4 + 50×2 = 500 EXP
  Level 5: 100×25 + 50×5 = 2750 EXP
  Level 10: 100×100 + 50×10 = 10,500 EXP
  
Maximum Level: 41
```

### Stat Growth

```asm
; ==============================================================================
; LevelUpCharacter - Apply level-up stat increases
; ==============================================================================
; Inputs:
;   X = Character index
; ==============================================================================
LevelUpCharacter:
    ; Increment level
    inc CharacterLevel,x
    
    ; HP increase
    lda HPGrowthTable,x     ; Get HP growth rate
    clc
    adc CharacterMaxHP,x
    sta CharacterMaxHP,x
    sta CharacterCurrentHP,x ; Heal to full
    
    ; MP increase
    lda MPGrowthTable,x
    clc
    adc CharacterMaxMP,x
    sta CharacterMaxMP,x
    sta CharacterCurrentMP,x ; Restore to full
    
    ; Attack increase
    lda AttackGrowthTable,x
    clc
    adc CharacterAttack,x
    sta CharacterAttack,x
    
    ; Defense increase
    lda DefenseGrowthTable,x
    clc
    adc CharacterDefense,x
    sta CharacterDefense,x
    
    ; Display level-up message
    jsr ShowLevelUpMessage
    
    rts
```

### Stat Growth Tables

```
Benjamin Growth (per level):
  HP: +8-12 (random variance)
  MP: +2-4
  Attack: +2-3
  Defense: +1-2
  Speed: +1 (every 3 levels)
  Magic: +1-2

Kaeli Growth (per level):
  HP: +6-10
  MP: +3-5
  Attack: +1-2
  Defense: +1-2
  Speed: +1-2
  Magic: +2-3

Phoebe Growth (per level):
  HP: +7-11
  MP: +2-4
  Attack: +2-3
  Defense: +1-2
  Speed: +2 (every 2 levels)
  Magic: +1-2

Tristam Growth (per level):
  HP: +8-12
  MP: +1-3
  Attack: +2-4
  Defense: +1-2
  Speed: +1
  Magic: +1
```

## Battle Rewards

### GP (Gold Points)

```
GP Awarded = Enemy.BaseGP × Multiplier

Multipliers:
  - Rare enemy: ×2
  - Bonus GP flag: ×1.5
  - Overkill: ×1.2

GP is shared among party members
Maximum GP: 9999
```

### Item Drops

```
Drop System:
  Each enemy has 2 drop slots:
    - Common drop (25% chance)
    - Rare drop (5% chance)
  
Drop Rate Modifiers:
  - Thief accessory equipped: +10% to all drops
  - Lucky status: +5% to rare drops
  
Drop Table Example:
    Enemy: Goblin
      Common: Cure Potion (25%)
      Rare: Antidote (5%)
```

### Victory Rewards Code

```asm
; ==============================================================================
; AwardBattleRewards - Give EXP, GP, and items
; ==============================================================================
AwardBattleRewards:
    ; Calculate total EXP
    jsr CalculateTotalEXP
    sta $10                 ; Save EXP
    
    ; Award EXP to each party member
    ldx #$00
.expLoop:
    lda PartyStatus,x
    bmi .nextEXP            ; Skip if KO'd
    
    lda $10                 ; Get EXP
    clc
    adc CharacterEXP,x
    sta CharacterEXP,x
    bcc .checkLevelUp
    
    ; EXP overflow (carry set)
    inc CharacterEXP+1,x
    
.checkLevelUp:
    jsr CheckForLevelUp
    
.nextEXP:
    inx
    cpx #$03
    bcc .expLoop
    
    ; Award GP
    jsr CalculateTotalGP
    clc
    adc PartyGP
    sta PartyGP
    bcc .itemDrops
    inc PartyGP+1
    
.itemDrops:
    ; Check for item drops
    jsr RollForItemDrops
    
    ; Display results
    jsr ShowRewardsScreen
    
    rts
```

## Code Locations

### Battle Initialization

**File**: `src/asm/bank_0B_documented.asm`

```asm
InitializeBattle:           ; Setup battle state
    ; Located at $0b:8000
    
LoadEnemyData:              ; Load enemy stats
    ; Located at $0b:8123
    
LoadBattleBackground:       ; Load battle scene
    ; Located at $0b:8234
    
InitializeATB:              ; Reset ATB gauges
    ; Located at $0b:8345
```

### Battle Loop

**File**: `src/asm/bank_0B_documented.asm`

```asm
BattleMainLoop:             ; Main battle update
    ; Located at $0b:9000
    
UpdateATBGauges:            ; Fill ATB gauges
    ; Located at $0b:9123
    
ProcessTurns:               ; Handle ready turns
    ; Located at $0b:9234
    
CheckBattleEnd:             ; Check win/lose
    ; Located at $0b:9345
```

### Damage Calculation

**File**: `src/asm/bank_0B_documented.asm`

```asm
CalculatePhysicalDamage:    ; Physical damage formula
    ; Located at $0b:A000
    
CalculateMagicDamage:       ; Magic damage formula
    ; Located at $0b:A123
    
ApplyElementalModifier:     ; Apply element bonuses
    ; Located at $0b:A234
    
CheckCriticalHit:           ; Roll for critical
    ; Located at $0b:A345
```

### AI System

**File**: `src/asm/bank_0B_documented.asm`

```asm
EnemyAI:                    ; Main AI decision
    ; Located at $0b:B000
    
AIPattern_Simple:           ; Simple attack AI
    ; Located at $0b:B123
    
AIPattern_MagicUser:        ; Magic-focused AI
    ; Located at $0b:B234
    
AIPattern_Boss:             ; Complex boss AI
    ; Located at $0b:B345
```

### Status Effects

**File**: `src/asm/bank_0B_documented.asm`

```asm
ProcessStatusEffects:       ; Apply status each turn
    ; Located at $0b:C000
    
ApplyPoison:                ; Poison damage
    ; Located at $0b:C123
    
ApplyRegen:                 ; Regen healing
    ; Located at $0b:C234
    
CheckStatusResistance:      ; Check immunity
    ; Located at $0b:C345
```

## Performance Considerations

### Battle Timing

```
60 FPS Target:
  - ATB updates: Every frame
  - Animation frames: 2-4 frames per step
  - Damage calculation: < 1 frame
  - AI decision: < 1 frame
  
Critical path:
  - Keep battle loop under 16ms
  - Use lookup tables for calculations
  - Minimize sprite updates
```

### Memory Usage

```
Battle RAM:
  - Party data: 256 bytes
  - Enemy data: 512 bytes (8 enemies × 64 bytes)
  - ATB gauges: 11 bytes
  - Status effects: 32 bytes
  - Damage buffer: 64 bytes
  
Total: ~900 bytes
```

## Debug Tools

### Battle Testing (Mesen-S)

- **Memory Viewer**: Inspect battle state
- **Debugger**: Breakpoint on damage calc
- **Event Viewer**: Track ATB updates
- **Sprite Viewer**: Check enemy positioning

### Debug Commands

```asm
; Set enemy HP to 1 (instant kill)
DebugKillEnemy:
    lda #$01
    sta EnemyHP,x
    rts

; Fill party ATB instantly
DebugReadyParty:
    lda #$ff
    sta PartyATB+0
    sta PartyATB+1
    sta PartyATB+2
    rts
```

## See Also

- **[MODDING_GUIDE.md](MODDING_GUIDE.md)** - How to modify battle mechanics
- **[data_formats.md](data_formats.md)** - Enemy and character data structures
- **[GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md)** - Battle graphics rendering

---

**For modding battles**, see [MODDING_GUIDE.md](MODDING_GUIDE.md#character-stats).

**For enemy data format**, see [data_formats.md](data_formats.md).
