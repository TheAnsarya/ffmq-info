# FFMQ Label Naming Conventions

**Version:** 1.0  
**Last Updated:** November 1, 2025  
**Status:** Official Standard

## Table of Contents

1. [Overview](#overview)
2. [General Principles](#general-principles)
3. [RAM Variable Conventions](#ram-variable-conventions)
4. [ROM Data Conventions](#rom-data-conventions)
5. [Pointer Conventions](#pointer-conventions)
6. [Graphics Conventions](#graphics-conventions)
7. [Hardware Register Conventions](#hardware-register-conventions)
8. [Code Label Conventions](#code-label-conventions)
9. [Special Cases](#special-cases)
10. [Examples](#examples)
11. [Quick Reference](#quick-reference)

---

## Overview

This document defines the official naming conventions for all labels in the Final Fantasy: Mystic Quest disassembly project. Consistent naming makes the codebase easier to understand, navigate, and maintain.

### Goals

- **Clarity**: Labels should clearly indicate their purpose
- **Consistency**: Similar items should follow similar patterns
- **Searchability**: Easy to find related labels
- **Brevity**: Short enough to be practical, long enough to be clear
- **Standards**: Follow established SNES/65816 conventions where applicable

---

## General Principles

### Case and Format

- Use **lowercase with underscores** (`snake_case`) for all labels
- Example: `player_x_pos`, `battle_state`, `text_buffer`

### Multi-byte Values

When a value spans multiple bytes, use suffixes:
- `_lo` for low byte
- `_hi` for high byte  
- `_bank` for bank byte

```assembly
!player_x_pos       = $40       ; 2-byte value (entire word)
!player_x_pos_lo    = $40       ; Low byte
!player_x_pos_hi    = $41       ; High byte
```

### Descriptive Naming

Labels should be self-documenting:
- ✅ Good: `enemy_hp_current`, `menu_selection_index`
- ❌ Bad: `var1`, `temp`, `data`

### Abbreviations

Use common abbreviations sparingly and consistently:
- `hp` - Hit Points
- `mp` - Magic Points
- `exp` - Experience
- `atb` - Active Time Battle
- `bg` - Background
- `sfx` - Sound Effects
- `rng` - Random Number Generator
- `dma` - Direct Memory Access
- `vram` - Video RAM
- `oam` - Object Attribute Memory
- `nmi` - Non-Maskable Interrupt
- `irq` - Interrupt Request

---

## RAM Variable Conventions

All RAM variables use the `!` prefix in asar syntax.

### Format Pattern

```
!<scope>_<system>_<item>_<detail>
```

### Scope Prefixes

**Temporary Variables** (short-lived, general purpose):
```assembly
!temp_ptr_1         = $00       ; Temporary pointer
!temp_byte_1        = $06       ; Temporary byte
!temp_word_1        = $09       ; Temporary word
!temp_index         = $0b       ; Temporary index/counter
!temp_flags         = $0c       ; Temporary flags
```

**Global Variables** (game-wide state):
```assembly
!game_mode          = $70       ; Current game mode
!frame_counter      = $71       ; Frame counter
!rng_seed           = $72       ; RNG seed
```

**System-specific Variables** (organized by game system):
```assembly
; Player system
!player_x_pos       = $40
!player_direction   = $44
!player_animation   = $47

; Battle system
!battle_state       = $90
!battle_phase       = $91
!active_character   = $92

; Graphics system
!vram_write_addr    = $20
!screen_brightness  = $29
!bg_mode            = $2a
```

### Common Patterns

**Position/Coordinates:**
```assembly
!player_x_pos
!player_y_pos
!map_x_pos
!map_y_pos
```

**State/Status:**
```assembly
!player_state
!battle_state
!game_state
!dialog_state
```

**Counters/Timers:**
```assembly
!frame_counter
!animation_counter
!fade_timer
!dialog_timer
```

**Flags:**
```assembly
!collision_flags
!status_flags
!event_flags
!input_flags
```

**Indices/Selections:**
```assembly
!menu_index
!item_index
!target_index
!command_index
```

### Character Stats Pattern

```assembly
!char1_hp_current       ; Current HP
!char1_hp_max           ; Maximum HP
!char1_level            ; Character level
!char1_exp              ; Experience points
!char1_weapon_id        ; Equipped weapon ID
!char1_armor_id         ; Equipped armor ID
```

### Input Pattern

```assembly
!joy1_current           ; Current frame input
!joy1_previous          ; Previous frame input
!joy1_pressed           ; Newly pressed buttons
!joy1_held              ; Held buttons
```

---

## ROM Data Conventions

ROM data labels use **UPPERCASE** with underscores.

### Format Pattern

```
<TYPE>_<Bank>_<System>_<Item>
```

### Data Type Prefixes

**DATA_** - Generic data tables
```assembly
DATA_00_InitialSettings:
DATA_03_MonsterStats:
DATA_07_ItemProperties:
```

**TBL_** - Lookup tables
```assembly
TBL_00_ExpCurve:
TBL_03_DamageFormulas:
TBL_07_ShopInventories:
```

**STR_** - String/text data
```assembly
STR_00_CharacterNames:
STR_01_ItemNames:
STR_02_DialogText:
```

**MAP_** - Map data
```assembly
MAP_00_WorldLayout:
MAP_01_ForestaTown:
MAP_02_HillOfDestiny:
```

### Examples by Category

**Item Data:**
```assembly
DATA_07_WeaponStats:
DATA_07_ArmorStats:
DATA_07_ConsumableEffects:
TBL_07_ItemPrices:
```

**Monster/Enemy Data:**
```assembly
DATA_03_EnemyStats:
DATA_03_EnemyAI:
DATA_03_EnemyRewards:
TBL_03_EncounterRates:
```

**Battle Data:**
```assembly
DATA_03_SpellEffects:
DATA_03_CommandList:
TBL_03_DamageMultipliers:
```

**Graphics Data:**
```assembly
GFX_00_TitleScreen:
GFX_01_CharacterSprites:
PAL_00_WorldMap:
PAL_01_BattleBackgrounds:
```

---

## Pointer Conventions

Pointers and addresses use specific prefixes based on what they point to.

### Pointer Prefixes

**PTR_** - General pointer to data
```assembly
PTR_DialogText:
PTR_MonsterData:
PTR_ItemTable:
```

**ADDR_** - Specific memory address
```assembly
ADDR_NMI_Handler:
ADDR_ResetVector:
ADDR_CharStats:
```

**VEC_** - Hardware vectors
```assembly
VEC_Reset:
VEC_NMI:
VEC_IRQ:
```

### Pointer Tables

```assembly
PTR_TBL_Dialogs:        ; Table of dialog pointers
	.dw PTR_Dialog_00
	.dw PTR_Dialog_01
	.dw PTR_Dialog_02

PTR_TBL_Sprites:        ; Table of sprite pointers
	.dw PTR_Sprite_Benjamin
	.dw PTR_Sprite_Kaeli
	.dw PTR_Sprite_Phoebe
```

---

## Graphics Conventions

Graphics-related labels use specific prefixes to indicate asset type.

### Graphics Prefixes

**GFX_** - Graphics data (tiles, sprites, backgrounds)
```assembly
GFX_00_TitleScreen:
GFX_01_Benjamin_Walk:
GFX_02_Enemy_Behemoth:
GFX_03_UI_MenuBorders:
```

**TILE_** - Individual tile data
```assembly
TILE_Grass:
TILE_Water:
TILE_Stone:
```

**SPR_** - Sprite data
```assembly
SPR_Benjamin_Stand:
SPR_Benjamin_Walk_Frame1:
SPR_Enemy_Flamerus:
```

**PAL_** - Palette data
```assembly
PAL_00_WorldMap:
PAL_01_ForestArea:
PAL_02_BattleBG:
PAL_03_MenuUI:
```

**TILEMAP_** - Tilemap arrangements
```assembly
TILEMAP_TitleScreen:
TILEMAP_MenuBG:
TILEMAP_BattleLayout:
```

### Animation Patterns

```assembly
; Animation sequences
GFX_Benjamin_Walk:
	GFX_Benjamin_Walk_Frame1:
	GFX_Benjamin_Walk_Frame2:
	GFX_Benjamin_Walk_Frame3:
	GFX_Benjamin_Walk_Frame4:

; State-based graphics
GFX_Benjamin_Stand:
GFX_Benjamin_Walk:
GFX_Benjamin_Run:
GFX_Benjamin_Jump:
```

### Palette Patterns

```assembly
PAL_Overworld_Day:
PAL_Overworld_Night:
PAL_Battle_Forest:
PAL_Battle_Cave:
PAL_Menu_Standard:
PAL_Menu_Status:
```

---

## Hardware Register Conventions

Use standard SNES hardware register names from official documentation.

### Standard Register Names

Always use the official SNES register names (NOT custom labels):

```assembly
; PPU Registers
INIDISP     = $2100     ; Display control
OBSEL       = $2101     ; Object size and base
OAMADDL     = $2102     ; OAM address (low)
OAMADDH     = $2103     ; OAM address (high)
BGMODE      = $2105     ; BG mode and character size
MOSAIC      = $2106     ; Mosaic enable and size
BG1SC       = $2107     ; BG1 tilemap address
VMAIN       = $2115     ; VRAM increment mode
VMADDL      = $2116     ; VRAM address (low)
VMADDH      = $2117     ; VRAM address (high)
VMDATAL     = $2118     ; VRAM data write (low)
VMDATAH     = $2119     ; VRAM data write (high)

; CPU Registers
NMITIMEN    = $4200     ; NMI/IRQ enable
WRIO        = $4201     ; I/O port write
WRMPYA      = $4202     ; Multiplicand A
WRMPYB      = $4203     ; Multiplicand B
WRDIVL      = $4204     ; Dividend (low)
WRDIVH      = $4205     ; Dividend (high)
WRDIVB      = $4206     ; Divisor
RDNMI       = $4210     ; NMI flag and version
TIMEUP      = $4211     ; IRQ flag
HVBJOY      = $4212     ; H/V blank and joypad status
RDIO        = $4213     ; I/O port read

; DMA Registers (per channel)
DMAP0       = $4300     ; DMA control (channel 0)
BBAD0       = $4301     ; DMA B-bus address
A1T0L       = $4302     ; DMA A-bus address (low)
A1T0H       = $4303     ; DMA A-bus address (high)
A1B0        = $4304     ; DMA A-bus bank
DAS0L       = $4305     ; DMA size (low)
DAS0H       = $4306     ; DMA size (high)
```

### Reference Documentation

For complete hardware register documentation, see:
- `docs/SYSTEM_ARCHITECTURE.md` - SNES hardware overview
- `docs/RAM_LABELS.md` - Memory-mapped register details
- Fullsnes documentation (external reference)

---

## Code Label Conventions

Code labels (subroutines, functions) use descriptive names.

### Subroutine Patterns

**Action verbs for functions:**
```assembly
LoadPlayerSprite:
UpdateBattleState:
DrawMenuItem:
CalculateDamage:
CheckCollision:
InitializeGame:
```

**State/system prefix:**
```assembly
; Battle system
Battle_Init:
Battle_ProcessTurn:
Battle_ApplyDamage:
Battle_CheckVictory:

; Menu system
Menu_Init:
Menu_HandleInput:
Menu_DrawCursor:
Menu_SelectItem:

; Graphics system
Graphics_LoadPalette:
Graphics_UpdateOAM:
Graphics_TransferVRAM:
```

### Handler Patterns

```assembly
NMI_Handler:
IRQ_Handler:
VBlank_Handler:
Joypad_Handler:
```

### Common Prefixes

- `Init_` - Initialization routines
- `Update_` - Per-frame update routines
- `Draw_` - Rendering routines
- `Load_` - Data loading routines
- `Process_` - Data processing routines
- `Check_` - Conditional checks
- `Calculate_` - Math/calculation routines
- `Handle_` - Input/event handlers

---

## Special Cases

### Bit Flags

When defining individual bits within a flag byte:

```assembly
; Status flags byte
!status_flags       = $a0

; Individual bit definitions (using constants)
STATUS_POISON       = %00000001     ; Bit 0
STATUS_BLIND        = %00000010     ; Bit 1
STATUS_SILENCE      = %00000100     ; Bit 2
STATUS_SLEEP        = %00001000     ; Bit 3
STATUS_PARALYZE     = %00010000     ; Bit 4
STATUS_CONFUSE      = %00100000     ; Bit 5
STATUS_PETRIFY      = %01000000     ; Bit 6
STATUS_FATAL        = %10000000     ; Bit 7
```

### Constants

All-caps with underscores for game constants:

```assembly
MAX_HP              = 999
MAX_PARTY_SIZE      = 2
INVENTORY_SIZE      = 64
NUM_WEAPONS         = 32
NUM_SPELLS          = 48

; Direction constants
DIR_UP              = 0
DIR_DOWN            = 1
DIR_LEFT            = 2
DIR_RIGHT           = 3

; Game mode constants
MODE_TITLE          = 0
MODE_OVERWORLD      = 1
MODE_BATTLE         = 2
MODE_MENU           = 3
```

### Magic Numbers

Replace magic numbers with named constants:

```assembly
; ❌ Bad
LDA #$0f
STA $2100

; ✅ Good
BRIGHTNESS_FULL = $0f
LDA #BRIGHTNESS_FULL
STA INIDISP
```

### Legacy Labels

When encountering existing labels that don't follow conventions:

1. Add a new compliant label
2. Keep old label with comment noting it's legacy
3. Eventually migrate code to use new label

```assembly
!player_x_pos       = $40       ; New convention
!general_address    = $0017     ; Legacy label (deprecated)
```

---

## Examples

### Complete RAM Variable Block

```assembly
; ============================================================================
; Battle System Variables ($90-$bf)
; ============================================================================

; Battle State
!battle_state           = $90       ; Current battle state
!battle_phase           = $91       ; Battle phase (init/command/execute/end)
!active_character       = $92       ; Active character index
!target_index           = $93       ; Target enemy/character index
!command_index          = $94       ; Selected command index

; ATB Gauges
!atb_char1              = $95       ; Character 1 ATB gauge (0-255)
!atb_char2              = $96       ; Character 2 ATB gauge
!atb_enemy1             = $97       ; Enemy 1 ATB gauge
!atb_enemy2             = $98       ; Enemy 2 ATB gauge

; Damage and Effects
!damage_value           = $99       ; Last damage value (2 bytes: $99-$9a)
!damage_value_lo        = $99       ; Damage value (low byte)
!damage_value_hi        = $9a       ; Damage value (high byte)
!hit_chance             = $9b       ; Hit chance percentage
!critical_flag          = $9c       ; Critical hit flag (1=critical)
!status_effect          = $9d       ; Status effect to apply
!exp_gained             = $9e       ; Experience gained (2 bytes: $9e-$9f)
!exp_gained_lo          = $9e       ; Experience gained (low byte)
!exp_gained_hi          = $9f       ; Experience gained (high byte)
```

### Complete ROM Data Block

```assembly
; ============================================================================
; Bank $07: Item and Equipment Data
; ============================================================================

; Weapon Statistics Table
DATA_07_WeaponStats:
	; Format: [Attack, Hit%, Critical%, Special Effect]
	.db 10, 90, 5, 0        ; Steel Sword
	.db 15, 92, 8, 0        ; Knight Sword
	.db 25, 95, 10, 1       ; Excalibur (Holy element)
	; ... more weapons

; Armor Statistics Table
DATA_07_ArmorStats:
	; Format: [Defense, Magic Defense, Evasion%, Special]
	.db 5, 3, 5, 0          ; Bronze Armor
	.db 10, 5, 8, 0         ; Steel Armor
	.db 20, 15, 12, 1       ; Aegis Shield (Fire resist)
	; ... more armor

; Item Price Table
TBL_07_ItemPrices:
	.dw 100                 ; Cure Potion
	.dw 500                 ; Elixir
	.dw 1000                ; Phoenix Down
	; ... more prices

; Item Name Pointers
PTR_TBL_ItemNames:
	.dw STR_Item_CurePotion
	.dw STR_Item_Elixir
	.dw STR_Item_PhoenixDown
```

### Complete Graphics Block

```assembly
; ============================================================================
; Bank $01: Character Sprite Graphics
; ============================================================================

; Benjamin Standing Sprites (all directions)
GFX_Benjamin_Stand:
GFX_Benjamin_Stand_Up:
	incbin "assets/graphics/benjamin_stand_up.2bpp"
GFX_Benjamin_Stand_Down:
	incbin "assets/graphics/benjamin_stand_down.2bpp"
GFX_Benjamin_Stand_Left:
	incbin "assets/graphics/benjamin_stand_left.2bpp"
GFX_Benjamin_Stand_Right:
	incbin "assets/graphics/benjamin_stand_right.2bpp"

; Benjamin Walking Animation (4 frames per direction)
GFX_Benjamin_Walk:
GFX_Benjamin_Walk_Up:
	GFX_Benjamin_Walk_Up_F1:
		incbin "assets/graphics/benjamin_walk_up_1.2bpp"
	GFX_Benjamin_Walk_Up_F2:
		incbin "assets/graphics/benjamin_walk_up_2.2bpp"
	GFX_Benjamin_Walk_Up_F3:
		incbin "assets/graphics/benjamin_walk_up_3.2bpp"
	GFX_Benjamin_Walk_Up_F4:
		incbin "assets/graphics/benjamin_walk_up_4.2bpp"

; Palettes for Benjamin
PAL_Benjamin_Overworld:
	incbin "assets/palettes/benjamin_overworld.pal"
PAL_Benjamin_Battle:
	incbin "assets/palettes/benjamin_battle.pal"
```

---

## Quick Reference

### RAM Variables Checklist

- [ ] Use `!` prefix for asar syntax
- [ ] Use lowercase with underscores
- [ ] Start with scope/system (temp, player, battle, etc.)
- [ ] Multi-byte values: use `_lo`, `_hi`, `_bank` suffixes
- [ ] Add descriptive comments with address ranges

### ROM Data Checklist

- [ ] Use UPPERCASE for label
- [ ] Use appropriate prefix: DATA_, TBL_, STR_, MAP_, GFX_, PAL_
- [ ] Include bank number if relevant
- [ ] Group related data together
- [ ] Document data format in comments

### Code Labels Checklist

- [ ] Use PascalCase for subroutines
- [ ] Start with action verb or system prefix
- [ ] Be descriptive and clear
- [ ] Group by system/functionality
- [ ] Add header comments for major sections

### Hardware Registers Checklist

- [ ] Use official SNES register names
- [ ] Reference fullsnes or official docs
- [ ] Don't create custom register aliases
- [ ] Add comments explaining usage

---

## Enforcement

### Code Reviews

All pull requests must follow these conventions. Reviewers should check:
1. Labels follow appropriate naming pattern
2. Comments explain complex or unclear labels
3. No conflicting or duplicate labels
4. Consistent with existing codebase

### Tools

The `tools/apply_labels.ps1` script (Issue #27) will help enforce conventions by validating label names before applying them.

### Updates

This document is living and may be updated as the project evolves. Changes require team approval through the pull request process.

---

## Related Documentation

- `docs/RAM_LABELS.md` - Complete RAM address documentation
- `docs/LABEL_GUIDE.md` - Guide to using labels effectively
- `docs/LABEL_CHANGELOG.md` - History of label changes
- `src/include/ffmq_ram_variables.inc` - Current RAM label definitions
- `docs/SYSTEM_ARCHITECTURE.md` - SNES hardware and memory architecture

---

**Questions or Suggestions?**  
Open an issue or discussion on the project repository.

**Last Updated:** November 1, 2025  
**Version:** 1.0  
**Issue:** #26 - Memory Labels: Label Naming Conventions
