# FFMQ Battle System Architecture

## Table of Contents

1. [Overview](#overview)
2. [Battle State Machine](#battle-state-machine)
3. [4D Coordinate System](#4d-coordinate-system)
4. [Combat Mechanics](#combat-mechanics)
5. [Enemy AI System](#enemy-ai-system)
6. [Battle Graphics & Animation](#battle-graphics--animation)
7. [Damage Calculation](#damage-calculation)
8. [Status Effects](#status-effects)
9. [Battle Memory Map](#battle-memory-map)
10. [Code Examples](#code-examples)

---

## Overview

The Final Fantasy Mystic Quest battle system is a sophisticated turn-based combat engine featuring real-time animations, a unique 4D coordinate system for positioning, dynamic enemy AI, and complex damage calculations.

### Key Features

- **Turn-based combat:** Classic Final Fantasy ATB (Active Time Battle) style
- **Real-time animation:** Sprite movement during attacks and spells
- **4D coordinates:** X/Y/Z/W system for precise positioning and effects
- **Dynamic AI:** Enemies adapt behavior based on battle state
- **Status effects:** Comprehensive status system (poison, sleep, etc.)
- **Combo system:** Multiple hits, critical strikes, elemental weaknesses

### Battle Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Battle Initialization                                    │
│    - Load enemy data                                        │
│    - Initialize battle state registers                      │
│    - Setup battle graphics                                  │
│    - Position combatants (4D coordinates)                   │
└───────────────────────┬─────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. ATB Loop (Main Battle)                                   │
│    ┌────────────────────────────────────────────────────┐  │
│    │ For each combatant:                                 │  │
│    │   - Update ATB gauge                                │  │
│    │   - Check for ready state                           │  │
│    │   - If ready:                                       │  │
│    │     * Player: Wait for input                        │  │
│    │     * Enemy: Execute AI decision                    │  │
│    │   - Process action:                                 │  │
│    │     * Calculate damage/healing                      │  │
│    │     * Animate attack                                │  │
│    │     * Apply effects                                 │  │
│    │     * Update battle state                           │  │
│    └────────────────────────────────────────────────────┘  │
│    │ Loop until victory or defeat                           │
└────┴────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Battle Conclusion                                        │
│    - Check win/lose conditions                             │
│    - Award EXP/GP if victory                               │
│    - Restore HP/MP if defeat (Game Over)                   │
│    - Cleanup battle state                                  │
│    - Return to field                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Battle State Machine

### State Registers ($0C50-$0C5F)

The battle system uses 16 state registers for managing combat:

```assembly
!battle_state_c50 = $0c50         ; Primary battle state
!sprite_data_c51  = $0c51         ; Sprite data/animation state
!battle_state_c52 = $0c52         ; Secondary state flags
!battle_state_c53 = $0c53         ; Tertiary state flags
!battle_state_c54 = $0c54         ; Active combatant index
!battle_state_c55 = $0c55         ; Target selection state
!battle_state_c56 = $0c56         ; Action type (attack/magic/item)
!battle_state_c57 = $0c57         ; Animation phase
!battle_state_c58 = $0c58         ; Damage calculation temp
!battle_state_c59 = $0c59         ; Hit/miss determination
!battle_state_c5a = $0c5a         ; Status effect flags
!battle_state_c5b = $0c5b         ; Combo counter
!battle_state_c5c = $0c5c         ; Critical hit flag
!battle_state_c5d = $0c5d         ; Element type
!battle_state_c5e = $0c5e         ; Battle timer (for timed events)
!battle_state_c5f = $0c5f         ; Reserved / extended state
```

### Main State Machine

```
┌──────────────────┐
│ STATE_INIT       │ ($00)
│ - Load enemies   │
│ - Init registers │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ STATE_READY      │ ($01)
│ - Wait for ATB   │
│ - Update gauges  │
└────────┬─────────┘
         ↓ (ATB full)
┌──────────────────┐
│ STATE_INPUT      │ ($02) [Player turn]
│ - Show menu      │
│ - Wait selection │
└────────┬─────────┘
         ↓ (or)
┌──────────────────┐
│ STATE_AI         │ ($03) [Enemy turn]
│ - Execute AI     │
│ - Select action  │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ STATE_ANIMATE    │ ($04)
│ - Move sprites   │
│ - Play SFX       │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ STATE_CALCULATE  │ ($05)
│ - Compute damage │
│ - Apply effects  │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ STATE_APPLY      │ ($06)
│ - Update HP/MP   │
│ - Check death    │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ STATE_CHECK_WIN  │ ($07)
│ - All enemies?   │
│ - Player dead?   │
└────────┬─────────┘
         ↓ (continue) or ↓ (end)
     Back to READY    STATE_VICTORY ($08)
                      STATE_DEFEAT ($09)
```

### State Transitions

| From State       | Condition                | To State        |
|------------------|--------------------------|-----------------|
| INIT             | Setup complete           | READY           |
| READY            | Player ATB full          | INPUT           |
| READY            | Enemy ATB full           | AI              |
| INPUT            | Player selects action    | ANIMATE         |
| AI               | AI decides action        | ANIMATE         |
| ANIMATE          | Animation complete       | CALCULATE       |
| CALCULATE        | Damage computed          | APPLY           |
| APPLY            | Effects applied          | CHECK_WIN       |
| CHECK_WIN        | All enemies defeated     | VICTORY         |
| CHECK_WIN        | Player defeated          | DEFEAT          |
| CHECK_WIN        | Battle continues         | READY           |

---

## 4D Coordinate System

### Coordinate Registers ($0C60-$0C6D)

FFMQ uses a unique 4-dimensional coordinate system for battle positioning:

```assembly
!battle_coord_x_lo = $0c60        ; X coordinate (low byte)
!battle_coord_x_hi = $0c61        ; X coordinate (high byte)
!battle_coord_y_lo = $0c64        ; Y coordinate (low byte)
!battle_coord_y_hi = $0c65        ; Y coordinate (high byte)
!battle_coord_z_lo = $0c68        ; Z coordinate (low byte)
!battle_coord_z_hi = $0c69        ; Z coordinate (high byte)
!battle_coord_w_lo = $0c6c        ; W coordinate (low byte)
!battle_coord_w_hi = $0c6d        ; W coordinate (high byte)
```

### Dimension Meanings

| Dimension | Purpose                           | Range       | Units           |
|-----------|-----------------------------------|-------------|-----------------|
| X         | Horizontal screen position        | 0-255       | Pixels          |
| Y         | Vertical screen position          | 0-223       | Pixels (NTSC)   |
| Z         | Depth / parallax layer            | 0-255       | Depth units     |
| W         | Scale / rotation / effect param   | 0-4096      | Fixed point     |

#### X Coordinate (Horizontal Position)

- **Range:** 0-255 pixels
- **Purpose:** Left-right position on screen
- **Player position:** Typically 32-64 (left side)
- **Enemy positions:** Typically 160-224 (right side)

**Example positions:**
```
X = 40   : Player character (default)
X = 48   : Player during attack animation (moved right)
X = 180  : Enemy 1 (far right)
X = 160  : Enemy 2 (center-right)
X = 140  : Enemy 3 (slightly right)
```

#### Y Coordinate (Vertical Position)

- **Range:** 0-223 pixels (NTSC), 0-239 (PAL)
- **Purpose:** Top-bottom position on screen
- **Vertical center:** 112 (NTSC)
- **Ground level:** ~140-160
- **Air/flying:** ~60-90

**Example positions:**
```
Y = 112  : Center of screen
Y = 150  : Ground level (walking enemies)
Y = 80   : Flying enemies (aerial)
Y = 70   : Jump/attack peak
```

#### Z Coordinate (Depth)

- **Range:** 0-255 depth units
- **Purpose:** Foreground/background separation, parallax
- **Foreground:** 0-64 (closer to camera)
- **Middle ground:** 65-128 (normal battle plane)
- **Background:** 129-255 (farther from camera)

**Z-depth effects:**
```
Z = 0    : Extreme foreground (spell effects)
Z = 32   : Near foreground (attack animations)
Z = 64   : Player/enemy plane (main battle)
Z = 128  : Background effects
Z = 192  : Far background (environment)
Z = 255  : Distant background (sky/horizon)
```

**Parallax formula:**
```
screen_offset = base_position + (Z / 64) * parallax_speed
```

#### W Coordinate (Scale/Rotation Parameter)

- **Range:** 0-4096 (fixed-point: 0.0 to 16.0)
- **Purpose:** Multi-purpose effect parameter
- **Typical uses:**
  - Sprite scaling (1.0 = normal size, 2.0 = 2× size)
  - Rotation angle (0-360 degrees mapped to 0-4096)
  - Effect intensity (transparency, color modulation)

**W as scale factor:**
```
W = 256   : 0.25× size (shrink to 25%)
W = 512   : 0.5× size (half size)
W = 1024  : 1.0× size (normal)
W = 2048  : 2.0× size (double)
W = 4096  : 4.0× size (maximum zoom)
```

**W as rotation angle:**
```
W = 0     : 0° (no rotation)
W = 1024  : 90° rotation
W = 2048  : 180° rotation
W = 3072  : 270° rotation
W = 4096  : 360° (full rotation, back to 0°)
```

### 4D Coordinate Array System

For multiple combatants (player + 3 enemies max), coordinates are stored in arrays:

```assembly
; Combatant 0 (Player)
!battle_coord_x_lo+$00 = X position low
!battle_coord_x_hi+$00 = X position high
!battle_coord_y_lo+$00 = Y position low
!battle_coord_y_hi+$00 = Y position high
!battle_coord_z_lo+$00 = Z depth low
!battle_coord_z_hi+$00 = Z depth high
!battle_coord_w_lo+$00 = W parameter low
!battle_coord_w_hi+$00 = W parameter high

; Combatant 1 (Enemy 1)
!battle_coord_x_lo+$08 = X position low  ; +8 bytes offset
!battle_coord_x_hi+$08 = X position high
; ... (Y, Z, W similarly offset)

; Combatant 2 (Enemy 2)
!battle_coord_x_lo+$10 = X position low  ; +16 bytes offset
; ...

; Combatant 3 (Enemy 3)
!battle_coord_x_lo+$18 = X position low  ; +24 bytes offset
; ...
```

**Array indexing:**
```assembly
; Load enemy 2's X coordinate
ldx #$10                          ; Enemy 2 offset (16 bytes)
rep #$30                          ; 16-bit mode
lda.w !battle_coord_x_lo,x       ; Load X coordinate
sep #$30
```

### Coordinate Transformation Pipeline

```
Raw Coordinates
      ↓
┌─────────────────────────┐
│ Apply Z-depth parallax  │
│ screen_x = x + (z/64)*p │
│ screen_y = y + (z/64)*p │
└────────┬────────────────┘
         ↓
┌─────────────────────────┐
│ Apply W scaling         │
│ scaled_x = screen_x * w │
│ scaled_y = screen_y * w │
└────────┬────────────────┘
         ↓
┌─────────────────────────┐
│ Screen clipping         │
│ Clamp to 0-255, 0-223   │
└────────┬────────────────┘
         ↓
   Final Screen Position
         ↓
   Sprite Positioning
```

---

## Combat Mechanics

### ATB (Active Time Battle) System

FFMQ uses a simplified ATB system:

#### ATB Gauge Mechanics

```assembly
; ATB data structure (per combatant)
atb_gauge:      .dw $0000         ; Current ATB value (0-1000)
atb_speed:      .db $32           ; Charge speed (50 = normal)
atb_ready_flag: .db $00           ; 0 = charging, 1 = ready

; ATB update (called each frame)
UpdateATB:
    lda atb_ready_flag            ; Check if already ready
    bne .skip_update              ; Skip if ready
    
    ; Increment ATB gauge
    rep #$30                      ; 16-bit mode
    lda atb_gauge
    clc
    adc atb_speed                 ; Add speed
    cmp #1000                     ; Check if full
    bcc .not_full
    lda #1000                     ; Cap at 1000
    sep #$30
    lda #$01
    sta atb_ready_flag            ; Mark ready
    bra .done
.not_full:
    sta atb_gauge                 ; Store gauge
    sep #$30
.done:
.skip_update:
    rts
```

**ATB Speed Factors:**
- Base speed: 50 units/frame
- Haste status: ×2 speed (100 units/frame)
- Slow status: ×0.5 speed (25 units/frame)
- Paralyzed: 0 speed (frozen)

**Time to ready:**
```
Normal:     1000 / 50 = 20 frames (~0.33 seconds)
Haste:      1000 / 100 = 10 frames (~0.17 seconds)
Slow:       1000 / 25 = 40 frames (~0.67 seconds)
```

### Turn Order

Combatants act in order of ATB gauge completion:

```
Frame 0:   All ATB = 0
Frame 10:  Enemy A ATB = 500, Player ATB = 300, Enemy B ATB = 200
Frame 20:  Enemy A ATB = 1000 (READY) ← Acts first
Frame 25:  Player ATB = 1000 (READY)  ← Acts second
Frame 30:  Enemy B ATB = 1000 (READY) ← Acts third
```

### Action Types

| Action Type | ID   | Affects       | Animation Time |
|-------------|------|---------------|----------------|
| Attack      | $00  | Single target | 30-45 frames   |
| Magic       | $01  | Single/all    | 60-120 frames  |
| Item        | $02  | Single/all    | 30 frames      |
| Defend      | $03  | Self          | 10 frames      |
| Run         | $04  | All (escape)  | 20 frames      |
| Weapon      | $05  | Single target | 40-60 frames   |
| Special     | $06  | Varies        | Varies         |

---

## Enemy AI System

### AI Decision Tree

Enemy AI uses a priority-based decision system:

```
┌─────────────────────────────────────────────────┐
│ 1. Check Critical Conditions                    │
│    - HP < 25%? → Use healing/desperate attack   │
│    - Status effect? → Attempt cure              │
└───────────────────┬─────────────────────────────┘
                    ↓ No critical
┌─────────────────────────────────────────────────┐
│ 2. Check Player Vulnerabilities                 │
│    - Player HP < 50%? → Aggressive attack       │
│    - Player has weakness? → Exploit element     │
│    - Player defending? → Use piercing attack    │
└───────────────────┬─────────────────────────────┘
                    ↓ No vulnerabilities
┌─────────────────────────────────────────────────┐
│ 3. Use Preset Pattern                           │
│    - Rotate through action pattern              │
│    - E.g., [Attack, Attack, Magic, Attack]      │
└───────────────────┬─────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 4. Execute Selected Action                      │
│    - Target selection                           │
│    - Damage calculation                         │
│    - Animation & effects                        │
└─────────────────────────────────────────────────┘
```

### AI Behavior Types

| Behavior ID | Name           | Pattern                               |
|-------------|----------------|---------------------------------------|
| $00         | Aggressive     | 80% physical, 20% magic               |
| $01         | Balanced       | 50% physical, 30% magic, 20% special  |
| $02         | Defensive      | 40% physical, 20% magic, 40% defend   |
| $03         | Magic-focused  | 20% physical, 70% magic, 10% special  |
| $04         | Support        | 30% physical, 30% magic, 40% buff     |
| $05         | Berserker      | 100% physical (random target)         |
| $06         | Strategic      | Adaptive (exploit weaknesses)         |
| $07         | Boss           | Scripted patterns with phases         |

### Target Selection AI

```assembly
; AI target selection
SelectTarget:
    lda enemy_ai_type
    cmp #$06                      ; Strategic AI?
    beq .strategic
    cmp #$05                      ; Berserker?
    beq .random
    ; Default: Attack player
    lda #$00                      ; Player is combatant 0
    sta target_index
    rts

.random:
    jsr RandomNumber              ; Get random value
    and #$03                      ; Mod 4 (0-3 combatants)
    sta target_index
    rts

.strategic:
    ; Find weakest/lowest HP target
    lda #$00
    sta target_index
    lda #$ff
    sta lowest_hp                 ; Start with max
    
    ldx #$00
.check_loop:
    lda combatant_hp,x            ; Load HP
    cmp lowest_hp
    bcs .not_lower
    sta lowest_hp                 ; New lowest
    stx target_index
.not_lower:
    inx
    cpx #$04                      ; Check all 4
    bcc .check_loop
    
    rts
```

---

## Battle Graphics & Animation

### DMA Graphics Coordination ($0CD0-$0CDC)

Battle animations use DMA for sprite updates:

```assembly
!dma_dest_addr      = $0cd0       ; DMA destination X
!dma_source_addr    = $0cd4       ; DMA source X+8
!dma_dest_addr_alt  = $0cd8       ; DMA source high
!dma_source_addr_alt = $0cdc      ; DMA destination high
```

### Animation System

Battle animations are coordinate-based:

#### Attack Animation Example

```
Frame 0:  Attacker X=40, Y=120, Z=64 (start position)
Frame 5:  Attacker X=60, Y=110, Z=48 (move forward/up)
Frame 10: Attacker X=80, Y=100, Z=32 (closer to enemy)
Frame 15: Attacker X=100, Y=95, Z=16 (strike position)
          [Play hit SFX, flash target]
Frame 20: Attacker X=80, Y=100, Z=32 (recoil)
Frame 25: Attacker X=60, Y=110, Z=48 (return)
Frame 30: Attacker X=40, Y=120, Z=64 (original position)
```

**Animation interpolation:**
```assembly
; Linear interpolation for smooth movement
; new_x = start_x + ((end_x - start_x) * progress / total_frames)

ComputeAnimationPosition:
    rep #$30                      ; 16-bit mode
    lda end_x
    sec
    sbc start_x                   ; delta_x = end_x - start_x
    sta delta_x
    
    lda current_frame
    sta temp_a
    lda delta_x
    sta temp_b
    jsr Multiply16                ; result = delta_x * current_frame
    
    lda result
    sta temp_a
    lda total_frames
    sta temp_b
    jsr Divide16                  ; result = (delta_x * current_frame) / total_frames
    
    lda start_x
    clc
    adc result                    ; new_x = start_x + result
    sta current_x
    sep #$30
    rts
```

### Spell Effect Animations

Magic spells use layered sprite animations:

**Example: Fire spell**
```
Layer 1: Fire ball sprite (main projectile)
  - Starts at caster position
  - Moves toward target (X/Y interpolation)
  - Z-depth decreases (comes forward)
  - W scale increases (grows larger)

Layer 2: Flame particles (background)
  - Random positions around projectile
  - Fade in/out (transparency via W parameter)
  - Slower movement (parallax via Z)

Layer 3: Impact flash (on hit)
  - Centered on target
  - Rapid scale increase (W: 256 → 2048)
  - Quick fade out (6 frames)
```

---

## Damage Calculation

### Physical Damage Formula

```
base_damage = (attack_power × attack_power) / defense
variance = base_damage × (random(224, 255) / 255)
final_damage = (base_damage + variance) / 2

if critical_hit:
    final_damage × 2
if elemental_weakness:
    final_damage × 1.5
if elemental_resist:
    final_damage × 0.5
if defending:
    final_damage × 0.5
```

### Magic Damage Formula

```
base_damage = magic_power × spell_multiplier
variance = base_damage × (random(240, 255) / 255)
final_damage = base_damage + variance

if elemental_weakness:
    final_damage × 2.0
if elemental_resist:
    final_damage × 0.25
if elemental_immune:
    final_damage = 0
```

### Critical Hit System

Critical hit chance:
```
base_crit_rate = 4% (1 in 25)
with_luck_boost = base_crit_rate + (luck / 100)
max_crit_rate = 25%

Random number < crit_rate → Critical!
```

### Damage Variance

Adds randomness to damage:
```assembly
CalculateDamageVariance:
    jsr RandomNumber              ; Get random 0-255
    and #$1f                      ; Mod 32 (0-31)
    clc
    adc #224                      ; Range: 224-255
    sta variance_factor           ; Store (88% - 100%)
    
    ; Apply variance
    lda base_damage
    sta temp_a
    lda variance_factor
    sta temp_b
    jsr Multiply8                 ; base_damage × variance_factor
    
    lda result
    sta temp_a
    lda #255
    sta temp_b
    jsr Divide8                   ; (base_damage × variance_factor) / 255
    
    sta damage_variance
    rts
```

---

## Status Effects

### Status Effect Flags

```assembly
status_flags:                     ; Bit flags (2 bytes)
  ; Byte 0
  .bit 0 = Poison               ; Lose HP each turn
  .bit 1 = Blind                ; Reduced accuracy
  .bit 2 = Sleep                ; Cannot act
  .bit 3 = Paralyze             ; Cannot act (different animation)
  .bit 4 = Silence              ; Cannot cast magic
  .bit 5 = Confuse              ; Random actions
  .bit 6 = Haste                ; Double ATB speed
  .bit 7 = Slow                 ; Half ATB speed
  
  ; Byte 1
  .bit 0 = Protect              ; Reduce physical damage
  .bit 1 = Shell                ; Reduce magic damage
  .bit 2 = Regen                ; Restore HP each turn
  .bit 3 = Reflect              ; Reflect spells
  .bit 4 = Zombie               ; Healing hurts, damage heals
  .bit 5 = Death                ; KO'd (0 HP)
  .bit 6 = Stone                ; Cannot act, increased defense
  .bit 7 = [Reserved]
```

### Status Effect Processing

```assembly
ProcessStatusEffects:
    lda status_flags              ; Load status byte 0
    
    ; Check poison
    bit #$01                      ; Test bit 0
    beq .not_poisoned
    lda current_hp
    sec
    sbc #$05                      ; Lose 5 HP
    bcs .store_poison_hp
    lda #$00                      ; Min 0 HP
.store_poison_hp:
    sta current_hp
    
.not_poisoned:
    ; Check regen
    lda status_flags+1            ; Load status byte 1
    bit #$04                      ; Test bit 2 (regen)
    beq .not_regen
    lda current_hp
    clc
    adc #$08                      ; Restore 8 HP
    cmp max_hp
    bcc .store_regen_hp
    lda max_hp                    ; Cap at max
.store_regen_hp:
    sta current_hp
    
.not_regen:
    ; ... (check other effects)
    rts
```

---

## Battle Memory Map

### Complete Battle Memory Layout

| Address Range    | Size   | Purpose                          |
|------------------|--------|----------------------------------|
| $0C50-$0C5F      | 16 B   | Battle state registers           |
| $0C60-$0C6D      | 14 B   | 4D coordinates (single)          |
| $0C60-$0C9F      | 64 B   | 4D coordinates (4 combatants)    |
| $0CA0-$0CAF      | 16 B   | HP/MP values (4 combatants)      |
| $0CB0-$0CBF      | 16 B   | Status effect flags              |
| $0CC0-$0CCF      | 16 B   | ATB gauges & timers              |
| $0CD0-$0CDC      | 13 B   | DMA graphics coordinates         |

### Combatant Data Structure

```assembly
; Per combatant (4 total: player + 3 enemies)
combatant_data:
  .struct
    x_coord_lo:     .dw 0         ; +$00: X coordinate
    y_coord_lo:     .dw 0         ; +$02: Y coordinate (note: skipped +1 byte)
    z_coord_lo:     .dw 0         ; +$04: Z coordinate (note: skipped +3 bytes)
    w_coord_lo:     .dw 0         ; +$06: W coordinate (note: skipped +5 bytes)
    hp_current:     .db 0         ; +$08: Current HP
    hp_max:         .db 0         ; +$09: Maximum HP
    mp_current:     .db 0         ; +$0A: Current MP
    mp_max:         .db 0         ; +$0B: Maximum MP
    status_flags:   .dw 0         ; +$0C: Status effect flags
    atb_gauge:      .dw 0         ; +$0E: ATB gauge value
  .endstruct
```

---

## Code Examples

### Example 1: Initialize Battle

```assembly
InitializeBattle:
    ; Clear all battle state registers
    lda #$00
    ldx #$00
.clear_loop:
    sta.w !battle_state_c50,x
    inx
    cpx #$10                      ; 16 registers
    bcc .clear_loop
    
    ; Set primary state to INIT
    lda #$00                      ; STATE_INIT
    sta.w !battle_state_c50
    
    ; Load enemy data
    jsr LoadEnemyData
    
    ; Initialize combatant positions
    jsr InitializeCombatantPositions
    
    ; Setup battle graphics
    jsr SetupBattleGraphics
    
    ; Transition to READY state
    lda #$01                      ; STATE_READY
    sta.w !battle_state_c50
    
    rts
```

### Example 2: Position Combatants (4D)

```assembly
InitializeCombatantPositions:
    ; Player position (combatant 0)
    rep #$30                      ; 16-bit mode
    lda #$0028                    ; X = 40
    sta.w !battle_coord_x_lo+$00
    lda #$0078                    ; Y = 120
    sta.w !battle_coord_y_lo+$00
    lda #$0040                    ; Z = 64 (normal depth)
    sta.w !battle_coord_z_lo+$00
    lda #$0400                    ; W = 1024 (1.0× scale)
    sta.w !battle_coord_w_lo+$00
    
    ; Enemy 1 position (combatant 1, offset +$08)
    lda #$00b4                    ; X = 180
    sta.w !battle_coord_x_lo+$08
    lda #$0050                    ; Y = 80
    sta.w !battle_coord_y_lo+$08
    lda #$0040                    ; Z = 64
    sta.w !battle_coord_z_lo+$08
    lda #$0400                    ; W = 1024
    sta.w !battle_coord_w_lo+$08
    
    ; Enemy 2 position (combatant 2, offset +$10)
    lda #$00a0                    ; X = 160
    sta.w !battle_coord_x_lo+$10
    lda #$0070                    ; Y = 112
    sta.w !battle_coord_y_lo+$10
    lda #$0048                    ; Z = 72 (slightly back)
    sta.w !battle_coord_z_lo+$10
    lda #$0400                    ; W = 1024
    sta.w !battle_coord_w_lo+$10
    
    ; Enemy 3 position (combatant 3, offset +$18)
    lda #$008c                    ; X = 140
    sta.w !battle_coord_x_lo+$18
    lda #$0090                    ; Y = 144
    sta.w !battle_coord_y_lo+$18
    lda #$0050                    ; Z = 80 (farther back)
    sta.w !battle_coord_z_lo+$18
    lda #$0400                    ; W = 1024
    sta.w !battle_coord_w_lo+$18
    
    sep #$30                      ; Back to 8-bit
    rts
```

### Example 3: Update ATB Gauges

```assembly
UpdateAllATBGauges:
    ldx #$00                      ; Combatant index
.loop:
    ; Check if combatant is alive
    lda combatant_hp,x
    beq .next                     ; Skip if dead
    
    ; Check if already ready
    lda atb_ready_flags,x
    bne .next                     ; Skip if ready
    
    ; Load ATB speed (affected by Haste/Slow)
    lda atb_speed,x
    
    ; Check for Haste status
    lda status_flags,x
    bit #$40                      ; Bit 6 = Haste
    beq .not_haste
    lda atb_speed,x
    asl a                         ; Double speed
    bra .apply_speed
.not_haste:
    ; Check for Slow status
    bit #$80                      ; Bit 7 = Slow
    beq .apply_speed
    lda atb_speed,x
    lsr a                         ; Half speed
    
.apply_speed:
    ; Add speed to gauge
    sta temp_speed
    rep #$30                      ; 16-bit mode
    lda atb_gauge,x
    clc
    adc temp_speed
    cmp #1000                     ; Check if full
    bcc .store_gauge
    lda #1000                     ; Cap at 1000
    sep #$30
    lda #$01
    sta atb_ready_flags,x         ; Mark ready
    rep #$30
.store_gauge:
    sta atb_gauge,x
    sep #$30
    
.next:
    inx
    inx                           ; 2-byte gauge
    cpx #$08                      ; 4 combatants × 2
    bcc .loop
    
    rts
```

### Example 4: Calculate Physical Damage

```assembly
CalculatePhysicalDamage:
    ; Load attacker's attack power
    ldx attacker_index
    lda combatant_attack,x
    sta temp_attack
    
    ; Load target's defense
    ldx target_index
    lda combatant_defense,x
    sta temp_defense
    
    ; base_damage = (attack × attack) / defense
    lda temp_attack
    sta temp_a
    sta temp_b
    jsr Multiply8                 ; attack × attack
    sta temp_product
    
    lda temp_product
    sta temp_a
    lda temp_defense
    sta temp_b
    jsr Divide8                   ; (attack × attack) / defense
    sta base_damage
    
    ; Add variance (88% - 100%)
    jsr CalculateDamageVariance   ; Returns damage_variance
    
    lda base_damage
    clc
    adc damage_variance
    lsr a                         ; Divide by 2 (average)
    sta final_damage
    
    ; Check for critical hit
    lda.w !battle_state_c5c       ; Critical hit flag
    beq .no_crit
    lda final_damage
    asl a                         ; Double damage
    sta final_damage
.no_crit:
    
    ; Check for elemental weakness/resistance
    jsr ApplyElementalModifiers
    
    ; Check if target defending
    ldx target_index
    lda combatant_defend_flag,x
    beq .not_defending
    lda final_damage
    lsr a                         ; Half damage
    sta final_damage
.not_defending:
    
    ; Store result
    lda final_damage
    sta damage_result
    
    rts
```

### Example 5: Attack Animation

```assembly
PlayAttackAnimation:
    ; Save original position
    ldx attacker_index
    lda #$08                      ; Offset multiplier
    jsr MultiplyA                 ; A = index × 8
    tax                           ; X = coordinate offset
    
    rep #$30                      ; 16-bit mode
    lda.w !battle_coord_x_lo,x
    sta original_x
    lda.w !battle_coord_y_lo,x
    sta original_y
    lda.w !battle_coord_z_lo,x
    sta original_z
    sep #$30
    
    ; Set animation parameters
    lda #30                       ; 30 frames total
    sta anim_total_frames
    lda #$00
    sta anim_current_frame
    
    ; Calculate target position (move toward enemy)
    rep #$30
    lda original_x
    clc
    adc #$003c                    ; Move right 60 pixels
    sta anim_end_x
    lda original_y
    sec
    sbc #$0014                    ; Move up 20 pixels
    sta anim_end_y
    lda original_z
    sec
    sbc #$0020                    ; Move forward 32 depth
    sta anim_end_z
    sep #$30
    
.anim_loop:
    ; Compute interpolated position
    jsr ComputeAnimationPosition  ; Updates current_x/y/z
    
    ; Update sprite position
    rep #$30
    lda current_x
    sta.w !battle_coord_x_lo,x
    lda current_y
    sta.w !battle_coord_y_lo,x
    lda current_z
    sta.w !battle_coord_z_lo,x
    sep #$30
    
    ; Wait 1 frame
    jsr WaitOneFrame
    
    ; Check for strike frame (frame 15)
    lda anim_current_frame
    cmp #15
    bne .not_strike
    ; Play hit SFX, flash target
    jsr PlayHitSound
    jsr FlashTarget
    jsr ApplyDamage               ; Actually apply damage
.not_strike:
    
    inc anim_current_frame
    lda anim_current_frame
    cmp anim_total_frames
    bcc .anim_loop
    
    ; Return to original position (reverse animation)
    lda #15                       ; 15 frames return
    sta anim_total_frames
    lda #$00
    sta anim_current_frame
    
    rep #$30
    lda current_x
    sta original_x                ; Start = current position
    lda.w !battle_coord_x_lo,x   ; (stored in registers)
    sta anim_end_x                ; End = original position
    ; ... (similar for Y, Z)
    sep #$30
    
.return_loop:
    jsr ComputeAnimationPosition
    rep #$30
    lda current_x
    sta.w !battle_coord_x_lo,x
    lda current_y
    sta.w !battle_coord_y_lo,x
    lda current_z
    sta.w !battle_coord_z_lo,x
    sep #$30
    
    jsr WaitOneFrame
    
    inc anim_current_frame
    lda anim_current_frame
    cmp anim_total_frames
    bcc .return_loop
    
    rts
```

### Example 6: Enemy AI Decision

```assembly
ExecuteEnemyAI:
    ldx enemy_index
    
    ; Load AI behavior type
    lda enemy_ai_type,x
    cmp #$07                      ; Boss AI?
    beq .boss_ai
    cmp #$06                      ; Strategic AI?
    beq .strategic_ai
    cmp #$05                      ; Berserker AI?
    beq .berserker_ai
    
    ; Default: Preset pattern AI
    jmp ProcessPresetPattern
    
.boss_ai:
    jmp ProcessBossAI
    
.strategic_ai:
    ; Check player HP
    lda player_hp
    lsr a                         ; Divide by 2
    cmp player_max_hp
    bcs .player_healthy           ; HP >= 50%
    
    ; Player weak, use strong attack
    lda #$10                      ; Strong attack action
    sta ai_selected_action
    lda #$00                      ; Target player
    sta ai_selected_target
    rts
    
.player_healthy:
    ; Check own HP
    lda enemy_hp,x
    cmp #$20                      ; HP < 32?
    bcs .enemy_healthy
    
    ; Enemy weak, attempt heal
    lda #$21                      ; Healing spell
    sta ai_selected_action
    stx ai_selected_target        ; Target self
    rts
    
.enemy_healthy:
    ; Normal attack
    lda #$00                      ; Basic attack
    sta ai_selected_action
    lda #$00                      ; Target player
    sta ai_selected_target
    rts
    
.berserker_ai:
    ; Random attack, random target
    jsr RandomNumber
    and #$0f                      ; Mod 16 (attack types 0-15)
    sta ai_selected_action
    jsr RandomNumber
    and #$03                      ; Mod 4 (combatants 0-3)
    sta ai_selected_target
    rts
```

---

## Document Info

**Version:** 1.0  
**Last Updated:** December 2024  
**Battle System:** Turn-based ATB  
**Max Combatants:** 4 (1 player + 3 enemies)  
**Coordinate System:** 4D (X/Y/Z/W)

**See Also:**
- `MEMORY_MAP.md` - Battle memory variables ($0C50-$0CDC)
- `GRAPHICS_SYSTEM.md` - Battle graphics and sprite animation
- `LABEL_USAGE_GUIDE.md` - Battle label usage examples
