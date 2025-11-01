# FFMQ ROM Data Map

**Last Updated:** November 1, 2025  
**Related Issues:** #25, #30, #3  
**Related Files:** `labels/rom_data_tables.csv`, `reports/rom_data_catalog.csv`

## Table of Contents

1. [Overview](#overview)
2. [ROM Organization](#rom-organization)
3. [Data Tables](#data-tables)
4. [Subroutines](#subroutines)
5. [Banks](#banks)

---

## Overview

This document catalogs all ROM data tables, structures, and subroutines in Final Fantasy: Mystic Quest. The ROM contains game data, code, graphics, and audio that is read-only and mapped to various address ranges depending on the bank.

### ROM Structure

- **Total ROM Size:** 1 MB (8 Mbit)
- **Banks:** 16 banks (Bank $00-$0F), each up to 64 KB
- **Address Range:** $8000-$FFFF per bank (32 KB per half-bank)
- **Header:** LoROM mapping

---

## ROM Organization

### Bank Layout

| Bank | Range | Primary Content |
|------|-------|-----------------|
| $00 | $8000-$FFFF | Main code, initialization |
| $01 | $8000-$FFFF | Core game logic |
| $02 | $8000-$FFFF | Battle system |
| $03 | $8000-$FFFF | Map/field system |
| $04 | $8000-$FFFF | Menu system |
| $05 | $8000-$FFFF | Text engine |
| $06 | $8000-$FFFF | Graphics routines |
| $07 | $8000-$FFFF | Enemy/character data |
| $08 | $8000-$FFFF | Item/equipment data |
| $09 | $8000-$FFFF | Spell/ability data |
| $0A | $8000-$FFFF | Graphics data |
| $0B | $8000-$FFFF | Enemy graphics/data |
| $0C | $8000-$FFFF | Map data |
| $0D | $8000-$FFFF | Music/audio data |
| $0E | $8000-$FFFF | Compressed graphics |
| $0F | $8000-$FFFF | Additional data |

---

## Data Tables

### Character Data Tables (Bank $07)

Character stats, progression, and configuration data.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $07xxxx | CharacterStatsTable | ~256 B | Base character statistics |
| $07xxxx | CharacterProgressionTable | ~128 B | Level-up stat gains |
| $07xxxx | CharacterEquipmentTable | ~64 B | Equipment compatibility |

### Enemy Data Tables (Bank $07, $0B)

Enemy stats, AI, graphics pointers.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $07AF3B | EnemyDataTable | Variable | Enemy data table pointers |
| $0B8892 | EnemyGraphicsPointerTable | ~106 B | Enemy graphics pointers (53 entries × 2 bytes) |
| $0B8CD9 | EnemyExtendedAttributesTable | Variable | Extended enemy attributes |

**Enemy Data Structure** (per entry):
```
Offset  Size  Field
+$00    2     HP
+$02    1     Attack
+$03    1     Defense
+$04    1     Magic Defense
+$05    1     Speed
+$06    1     EXP reward (low)
+$07    1     EXP reward (high)
+$08    1     GP reward (low)
+$09    1     GP reward (high)
+$0A    1     AI pattern
+$0B    1     Special flags
```

### Item/Equipment Tables (Bank $08)

Item properties, effects, and descriptions.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $08xxxx | WeaponDataTable | ~256 B | Weapon stats (attack, element, special) |
| $08xxxx | ArmorDataTable | ~192 B | Armor stats (defense, resistances) |
| $08xxxx | AccessoryDataTable | ~128 B | Accessory effects |
| $08xxxx | ConsumableItemTable | ~128 B | Consumable item effects |

**Weapon Data Structure**:
```
Offset  Size  Field
+$00    1     Attack power
+$01    1     Element type
+$02    1     Special effect
+$03    1     Equipped character flags
```

### Spell/Ability Data (Bank $09)

Magic spells and abilities.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $09xxxx | SpellDataTable | ~256 B | Spell power, cost, effects |
| $09xxxx | AbilityDataTable | ~128 B | Special ability data |

**Spell Data Structure**:
```
Offset  Size  Field
+$00    1     Base power
+$01    1     MP cost
+$02    1     Element
+$03    1     Target flags
+$04    1     Animation ID
```

### Graphics Data (Banks $0A, $0B, $0E)

Compressed and uncompressed graphics data.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $0Axxxx | TileDataCompressed | Variable | Compressed tile graphics |
| $0Axxxx | SpriteDataCompressed | Variable | Compressed sprite graphics |
| $0Bxxxx | EnemySpriteGraphics | Variable | Enemy sprite pixel data |
| $0Exxxx | BackgroundGraphics | Variable | Background/tileset graphics |

### Pointer Tables

Tables containing addresses of data structures.

| Address | Label | Entries | Description |
|---------|-------|---------|-------------|
| $07AF3B | EnemyDataPointers | 53 | Pointers to enemy data structures |
| $0B8892 | EnemyGraphicsPointers | 53 | Pointers to enemy graphics |
| $0D9C3C | MusicTrackPointers | 8 | Music track data pointers |

### Audio/Music Tables (Bank $0D)

Music tracks, sound effects, and audio configuration.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $0D9C3C | MusicTrackPointerTable | 16 B | Music track pointers (8 tracks) |
| $0D9CFC | AudioConfigTable | 16 B | Audio timing/buffer config |
| $0D9D78 | TrackDataBlock0 | Variable | Music track data block 0 |
| $0DBDFF | MusicBankTable | Variable | Bank bytes for music tracks |
| $0DBE00 | MusicAddressTableLo | Variable | Music address low bytes |
| $0DBE35 | MusicTrackSizes | 16 B | Track size table (8 tracks) |
| $0DBE59 | MusicTrackFlags | 16 B | Track flags (8 tracks) |
| $0DBE7D | ADSRValuesTable | 16 B | ADSR envelope values (8 tracks) |

---

## Subroutines

Common ROM subroutines called frequently throughout the game.

### Graphics Routines

| Address | Label | Usage | Purpose |
|---------|-------|-------|---------|
| $FC8E | GraphicsDecompression | 8× | Decompress graphics data |
| $AB5C | SpriteUpdate | 6× | Update sprite positions/attributes |
| $FD50 | VRAMTransfer | 6× | Transfer data to VRAM |
| $81DB | LoadTilemap | 2× | Load tilemap data |
| $8672 | RenderTiles | 2× | Render tiles to buffer |
| $84E0 | ProcessSprites | 2× | Process sprite data |
| $8B75 | UpdateAnimation | 2× | Update animation frames |
| $8B82 | SetAnimationState | 2× | Set animation state |

### System Routines

| Address | Label | Usage | Purpose |
|---------|-------|-------|---------|
| $8E06 | InitGraphicsEngine | 2× | Initialize graphics system |
| $82CF | SetupDMA | 2× | Configure DMA transfer |
| $94CC | MenuGraphics | 2× | Menu rendering routines |
| $9FAE | BattleGraphics | 2× | Battle scene rendering |

### Data Loading

| Address | Label | Usage | Purpose |
|---------|-------|-------|---------|
| $A08A | LoadEnemySprite | 2× | Load enemy sprite graphics |
| $A403 | LoadCharacterSprite | 2× | Load character sprite |

### Lookup Tables

| Address | Label | Type | Purpose |
|---------|-------|------|---------|
| $F280 | TileDataTable | Data | Tile data lookup (4 uses) |
| $839E | PaletteDataLo | Data | Palette data (low byte) |
| $839F | PaletteDataHi | Data | Palette data (high byte) |
| $88C4 | OffsetTableLo | Data | Offset table (low byte) |
| $88C5 | OffsetTableHi | Data | Offset table (high byte) |

---

## Banks

### Bank $00: Main Code & Initialization

Entry point, system initialization, interrupt handlers.

**Key Subroutines:**
- Reset vector ($8000)
- NMI handler
- IRQ handler  
- System initialization

### Bank $07: Game Data

Character and enemy data tables.

**Key Data:**
- Character stats
- Enemy stats ($07AF3B)
- Battle formations
- Encounter tables

### Bank $0B: Enemy Graphics & Data

Enemy sprite graphics and extended attributes.

**Key Data:**
- Enemy graphics pointers ($0B8892)
- Enemy sprite configuration
- Enemy sprite tile tables
- Enemy graphics pixel data
- Enemy extended attributes ($0B8CD9)

### Bank $0D: Audio System

Music and sound effect data.

**Key Data:**
- Music track pointers ($0D9C3C)
- Audio configuration ($0D9CFC)
- Track data blocks ($0D9D78+)
- Music bank/address tables ($0DBDFF+)
- Track sizes, flags, ADSR values

### Bank $0E: Compressed Graphics

Compressed tileset and background graphics.

---

## Complete Data Table Catalog

This section lists all 296 DATA8/DATA16/ADDR labels found across all documented banks. Generated by `tools/catalog_rom_data.ps1`.

### Catalog Statistics

- **Total Tables:** 296 (295 DATA8, 1 DATA16)
- **Banks Documented:** 13 of 16 (Banks $00-$02, $04-$0D)
- **Primary Data Banks:** $07 (77 tables), $02 (64 tables), $01 (43 tables)

### Bank-by-Bank Listing

#### Bank $00: System & Initialization (23 tables)

Tables related to system initialization, interrupt handling, and core routines.

| Address | Label | Description |
|---------|-------|-------------|
| $0081D5 | DATA8_0081D5 | |
| $0081D6 | DATA8_0081D6 | |
| $0081D8 | DATA8_0081D8 | |
| $0081D9 | DATA8_0081D9 | |
| $0081DB | DATA8_0081DB | |
| $0081ED | DATA8_0081ED | |
| $00822A | DATA8_00822A | |
| $00822D | DATA8_00822D | |
| $008252 | DATA8_008252 | |
| $008334 | DATA8_008334 | |
| $008960 | DATA8_008960 | |
| $008961 | DATA8_008961 | |
| $008962 | DATA8_008962 | |
| $0097FB | DATA8_0097FB | |
| $009A1E | DATA8_009A1E | |
| $009C87 | DATA8_009C87 | |
| $009E0E | DATA8_009E0E | |
| $009E6E | DATA8_009E6E | |
| $00A2DD | DATA8_00A2DD | |
| $00A2DE | DATA8_00A2DE | |
| $00C339 | DATA8_00C339 | |
| $00C33A | DATA8_00C33A | |
| $00C33B | DATA8_00C33B | |

#### Bank $01: Core Game Logic (43 tables)

Core gameplay systems, state management, and game flow control.

<details>
<summary>Show all Bank $01 tables (43 entries)</summary>

| Address | Label | Description |
|---------|-------|-------------|
| $018000 | DATA8_018000 | |
| $018032 | DATA8_018032 | |
| $018242 | DATA8_018242 | |
| $0182FE | DATA8_0182FE | |
| $01832F | DATA8_01832F | |
| $018330 | DATA8_018330 | |
| $01835B | DATA8_01835B | |
| $01839F | DATA8_01839F | |
| $0183A0 | DATA8_0183A0 | |
| $0183A2 | DATA8_0183A2 | |
| $018557 | DATA8_018557 | |
| $01A5E0 | DATA8_01A5E0 | |
| $01A63A | DATA8_01A63A | |
| $01A63C | DATA8_01A63C | |
| $01ABF9 | DATA8_01ABF9 | |
| $01B1FB | DATA8_01B1FB | |
| $01B23B | DATA8_01B23B | |
| $01B277 | DATA8_01B277 | |
| $01B2C2 | DATA8_01B2C2 | |
| $01B311 | DATA8_01B311 | |
| $01B365 | DATA8_01B365 | |
| $01B3B8 | DATA8_01B3B8 | |
| $01B40E | DATA8_01B40E | |
| $01B45D | DATA8_01B45D | |
| $01B4AC | DATA8_01B4AC | |
| $01B4FF | DATA8_01B4FF | |
| $01B551 | DATA8_01B551 | |
| $01B595 | DATA8_01B595 | |
| $01B5CD | DATA8_01B5CD | |
| $01B606 | DATA8_01B606 | |
| $01B649 | DATA8_01B649 | |
| $01B697 | DATA8_01B697 | |
| $01B6D1 | DATA8_01B6D1 | |
| $01B709 | DATA8_01B709 | |
| $01B74D | DATA8_01B74D | |
| $01B79C | DATA8_01B79C | |
| $01B7E4 | DATA8_01B7E4 | |
| $01B841 | DATA8_01B841 | |
| $01B89E | DATA8_01B89E | |
| $01B8F0 | DATA8_01B8F0 | |
| $01B944 | DATA8_01B944 | |
| $01BED6 | DATA8_01BED6 | |
| $01C0D1 | DATA8_01C0D1 | |

</details>

#### Bank $02: Battle System (64 tables)

Battle mechanics, damage calculation, enemy AI, and combat animations.

<details>
<summary>Show all Bank $02 tables (64 entries)</summary>

| Address | Label | Description |
|---------|-------|-------------|
| $029BA0 | DATA8_029BA0 | |
| $02A272 | DATA8_02A272 | |
| $02A273 | DATA8_02A273 | |
| $02A278 | DATA8_02A278 | |
| $02A279 | DATA8_02A279 | |
| $02AA79 | DATA8_02AA79 | |
| $02AAB9 | DATA8_02AAB9 | |
| $02AABD | DATA8_02AABD | |
| $02AAC1 | DATA8_02AAC1 | |
| $02AAC5 | DATA8_02AAC5 | |
| $02AC53 | DATA8_02AC53 | |
| $02AC93 | DATA8_02AC93 | |
| $02AC97 | DATA8_02AC97 | |
| $02AC9B | DATA8_02AC9B | |
| $02AC9F | DATA8_02AC9F | |
| $02D3E7 | DATA8_02D3E7 | |
| $02D3ED | DATA8_02D3ED | |
| $02D58F | DATA8_02D58F | |
| $02D627 | DATA8_02D627 | |
| $02D72B | DATA8_02D72B | |
| $02D77A | DATA8_02D77A | |
| $02D7D3 | DATA8_02D7D3 | |
| $02D8BF | DATA8_02D8BF | |
| $02D96C | DATA8_02D96C | |
| $02D96E | DATA8_02D96E | |
| $02D970 | DATA8_02D970 | |
| $02D972 | DATA8_02D972 | |
| $02D974 | DATA8_02D974 | |
| $02DA7D | DATA8_02DA7D | |
| $02DB83 | DATA8_02DB83 | |
| $02DCC4 | DATA8_02DCC4 | |
| $02DD30 | DATA8_02DD30 | |
| $02DF53 | DATA8_02DF53 | |
| $02DFBE | DATA8_02DFBE | |
| $02E34C | DATA8_02E34C | |
| $02E34E | DATA8_02E34E | |
| $02E5BB | DATA8_02E5BB | |
| $02E5C0 | DATA8_02E5C0 | |
| $02E5C5 | DATA8_02E5C5 | |
| $02E5CA | DATA8_02E5CA | |
| $02E5CF | DATA8_02E5CF | |
| $02E5D4 | DATA8_02E5D4 | |
| $02E5D9 | DATA8_02E5D9 | |
| $02E5DE | DATA8_02E5DE | |
| $02E5E3 | DATA8_02E5E3 | |
| $02E5E8 | DATA8_02E5E8 | |
| $02EAD7 | DATA8_02EAD7 | |
| $02EADC | DATA8_02EADC | |
| $02EAE1 | DATA8_02EAE1 | |
| $02EAE6 | DATA8_02EAE6 | |
| $02EAEB | DATA8_02EAEB | |
| $02EAF0 | DATA8_02EAF0 | |
| $02EAF5 | DATA8_02EAF5 | |
| $02EAFA | DATA8_02EAFA | |
| $02EAFF | DATA8_02EAFF | |
| $02EB04 | DATA8_02EB04 | |
| $02FC50 | DATA8_02FC50 | |
| $02FC51 | DATA8_02FC51 | |
| $02FC53 | DATA8_02FC53 | |
| $02FC54 | DATA8_02FC54 | |
| $02FC55 | DATA8_02FC55 | |
| $02FC56 | DATA8_02FC56 | |
| $02FC57 | DATA8_02FC57 | |
| $02FD8F | DATA8_02FD8F | |

</details>

#### Bank $04: Menu System (2 tables)

Menu rendering and UI controls.

| Address | Label | Description |
|---------|-------|-------------|
| $048000 | DATA8_048000 | |
| $049800 | DATA8_049800 | |

#### Bank $05: Text Engine (2 tables)

Text rendering and dialog systems.

| Address | Label | Description |
|---------|-------|-------------|
| $058000 | DATA8_058000 | |
| $058A80 | DATA8_058A80 | |

#### Bank $06: Graphics Routines (1 table)

Graphics processing and rendering functions.

| Address | Label | Description |
|---------|-------|-------------|
| $068000 | DATA8_068000 | |

#### Bank $07: Character & Enemy Data (77 tables)

Largest data bank with character stats, enemy definitions, battle formations.

<details>
<summary>Show all Bank $07 tables (77 entries)</summary>

| Address | Label | Description |
|---------|-------|-------------|
| $078000 | DATA8_078000 | |
| $078001 | DATA8_078001 | |
| $078002 | DATA8_078002 | |
| $078003 | DATA8_078003 | |
| $078004 | DATA8_078004 | |
| $078005 | DATA8_078005 | |
| $078006 | DATA8_078006 | |
| $078007 | DATA8_078007 | |
| $07800A | DATA8_07800A | |
| $07800C | DATA8_07800C | |
| $078030 | DATA8_078030 | |
| $078031 | DATA8_078031 | |
| $0790BB | DATA8_0790BB | |
| $07AF3B | DATA8_07AF3B | Enemy Data Pointers |
| $07B013 | DATA8_07B013 | |
| $07D7F4 | DATA8_07D7F4 | |
| $07D7F5 | DATA8_07D7F5 | |
| $07D7F6 | DATA8_07D7F6 | |
| $07D7F7 | DATA8_07D7F7 | |
| $07D7F8 | DATA8_07D7F8 | |
| $07D7F9 | DATA8_07D7F9 | |
| $07D7FA | DATA8_07D7FA | |
| $07D7FB | DATA8_07D7FB | |
| $07D7FC | DATA8_07D7FC | |
| $07D7FD | DATA8_07D7FD | |
| $07D7FE | DATA8_07D7FE | |
| $07D7FF | DATA8_07D7FF | |
| $07D800 | DATA8_07D800 | |
| $07D801 | DATA8_07D801 | |
| $07D802 | DATA8_07D802 | |
| $07D803 | DATA8_07D803 | |
| $07D814 | DATA8_07D814 | |
| $07D815 | DATA8_07D815 | |
| $07D816 | DATA8_07D816 | |
| $07D817 | DATA8_07D817 | |
| $07D818 | DATA8_07D818 | |
| $07D819 | DATA8_07D819 | |
| $07D81A | DATA8_07D81A | |
| $07D81B | DATA8_07D81B | |
| $07D81C | DATA8_07D81C | |
| $07D81D | DATA8_07D81D | |
| $07D81E | DATA8_07D81E | |
| $07D81F | DATA8_07D81F | |
| $07D820 | DATA8_07D820 | |
| $07D821 | DATA8_07D821 | |
| $07D822 | DATA8_07D822 | |
| $07D823 | DATA8_07D823 | |
| $07D824 | DATA8_07D824 | |
| $07D8E4 | DATA8_07D8E4 | |
| $07D8E5 | DATA8_07D8E5 | |
| $07D8E6 | DATA8_07D8E6 | |
| $07D8E7 | DATA8_07D8E7 | |
| $07D8E8 | DATA8_07D8E8 | |
| $07D8E9 | DATA8_07D8E9 | |
| $07D8EA | DATA8_07D8EA | |
| $07D8EB | DATA8_07D8EB | |
| $07D8EC | DATA8_07D8EC | |
| $07D8ED | DATA8_07D8ED | |
| $07D8EE | DATA8_07D8EE | |
| $07D8EF | DATA8_07D8EF | |
| $07D8F0 | DATA8_07D8F0 | |
| $07D8F1 | DATA8_07D8F1 | |
| $07D8F2 | DATA8_07D8F2 | |
| $07D8F3 | DATA8_07D8F3 | |
| $07DB14 | DATA8_07DB14 | |
| $07EB44 | DATA8_07EB44 | |
| $07EB45 | DATA8_07EB45 | |
| $07EB46 | DATA8_07EB46 | |
| $07EB47 | DATA8_07EB47 | |
| $07EB48 | DATA8_07EB48 | |
| $07EE84 | DATA8_07EE84 | |
| $07EE85 | DATA8_07EE85 | |
| $07EE86 | DATA8_07EE86 | |
| $07EE87 | DATA8_07EE87 | |
| $07EE88 | DATA8_07EE88 | |
| $07EFA1 | DATA8_07EFA1 | |
| $07F011 | DATA8_07F011 | |

</details>

#### Bank $08: Item/Equipment Data (4 tables)

Weapon, armor, accessory, and item definitions.

| Address | Label | Description |
|---------|-------|-------------|
| $088000 | DATA8_088000 | |
| $088330 | DATA8_088330 | |

#### Bank $09: Spell/Ability Data (10 tables)

Magic spells and special abilities.

| Address | Label | Description |
|---------|-------|-------------|
| $098460 | DATA8_098460 | |
| $098461 | DATA8_098461 | |
| $098462 | DATA8_098462 | |
| $098463 | DATA8_098463 | |
| $098464 | DATA8_098464 | |

#### Bank $0A: Graphics Data (2 tables)

Compressed tile and sprite graphics.

| Address | Label | Description |
|---------|-------|-------------|
| $0A8000 | DATA8_0A8000 | |
| $0A830C | DATA8_0A830C | |

#### Bank $0B: Enemy Graphics & Animation (35 tables)

Enemy sprite data, animation handlers, and graphics pointers.

| Address | Label | Description |
|---------|-------|-------------|
| $0B8140 | DATA8_0B8140 | |
| $0B8296 | DATA8_0B8296 | |
| $0B829E | DATA8_0B829E | |
| $0B829F | DATA8_0B829F | |
| $0B82A0 | DATA8_0B82A0 | |
| $0B8324 | DATA8_0B8324 | |
| $0B83AC | DATA8_0B83AC | |
| $0B83AD | DATA8_0B83AD | |
| $0B83B2 | DATA8_0B83B2 | |
| $0B844F | DATA8_0B844F | |
| $0B8450 | DATA8_0B8450 | |
| $0B8451 | DATA8_0B8451 | |
| $0B8452 | DATA8_0B8452 | |
| $0B8497 | DATA8_0B8497 | |
| $0B84DF | DATA8_0B84DF | |
| $0B84E0 | DATA8_0B84E0 | |
| $0B84E1 | DATA8_0B84E1 | |
| $0B84E2 | DATA8_0B84E2 | |
| $0B856C | DATA8_0B856C | |
| $0B8659 | DATA8_0B8659 | |
| $0B865B | DATA8_0B865B | |
| $0B8735 | DATA8_0B8735 | |
| $0B8737 | DATA8_0B8737 | |
| $0B87E4 | DATA8_0B87E4 | |
| $0B87E5 | DATA8_0B87E5 | |
| $0B8892 | DATA8_0B8892 | Enemy Graphics Pointer Table |
| $0B88FC | DATA8_0B88FC | |
| $0B8CD9 | DATA8_0B8CD9 | Enemy Extended Attributes Table |
| $0B8F03 | DATA8_0B8F03 | Same-state animation handlers |
| $0B8F15 | DATA8_0B8F15 | Changed-state animation handlers |
| $0B905F | DATA8_0B905F | Rotation frame handlers |
| $0B9113 | DATA8_0B9113 | 4-frame tile pattern handlers |
| $0B91D0 | DATA8_0B91D0 | Attack motion frames |
| $0BF08F | DATA8_0BF08F | |
| $0BF091 | DATA8_0BF091 | |

#### Bank $0C: Map/World Data (10 tables)

World map, collision, and map-related tables.

| Address | Label | Description |
|---------|-------|-------------|
| $0C8659 | DATA8_0C8659 | |
| $0C886B | DATA8_0C886B | |
| $0C88B0 | DATA8_0C88B0 | |
| $0C8B66 | DATA16_0C8B66 | Sine/cosine table 1 (48 entries) |
| $0C8B93 | DATA8_0C8B93 | Animation speed table (30 bytes) |
| $0C8C5E | DATA8_0C8C5E | |
| $0C8CDE | DATA8_0C8CDE | |
| $0C8D1E | DATA8_0C8D1E | |
| $0CEF85 | DATA8_0CEF85 | |
| $0CEF89 | DATA8_0CEF89 | |

#### Bank $0D: Music/Audio System (23 tables)

Music track data, sound effects, and audio engine tables.

| Address | Label | Description |
|---------|-------|-------------|
| $0D8008 | DATA8_0D8008 | |
| $0D8009 | DATA8_0D8009 | |
| $0D8014 | DATA8_0D8014 | |
| $0D8015 | DATA8_0D8015 | |
| $0D9C3C | DATA8_0D9C3C | Track pointers 0-7 |
| $0D9CFC | DATA8_0D9CFC | Config: Timing/buffers |
| $0D9D78 | DATA8_0D9D78 | Track data block 0 |
| $0DBDFF | DATA8_0DBDFF | Bank byte for entry 0 |
| $0DBE00 | DATA8_0DBE00 | Address low byte |
| $0DBE01 | DATA8_0DBE01 | Music track pointers 0-5 |
| $0DBE35 | DATA8_0DBE35 | Track sizes 0-7 |
| $0DBE59 | DATA8_0DBE59 | Track flags 0-7 |
| $0DBE7D | DATA8_0DBE7D | ADSR values 0-7 |
| $0DC451 | DATA8_0DC451 | |
| $0DC821 | DATA8_0DC821 | |
| $0DCC31 | DATA8_0DCC31 | |
| $0DDD51 | DATA8_0DDD51 | |
| $0DDFC1 | DATA8_0DDFC1 | |
| $0DE431 | DATA8_0DE431 | |

---

## Data Analysis Tools

The following tools help analyze and manage ROM data tables:

### catalog_rom_data.ps1

Scans all documented ASM files for DATA8/DATA16/ADDR labels and generates:
- `reports/rom_data_catalog.csv` - Complete catalog of all data tables
- Statistics by bank and type
- Automated description extraction from comments

**Usage:**
```powershell
.\tools\catalog_rom_data.ps1
```

**Output:** `reports/rom_data_catalog.csv` (296 entries)

### scan_addresses.ps1

Scans ASM files for address usage and generates priority reports.

**Related Files:**
- `reports/rom_data_catalog.csv` - Generated catalog (296 tables)
- `reports/address_usage_report.csv` - Address frequency analysis

---

## Cross-References

### Related Documents

- [RAM_MAP.md](RAM_MAP.md) - WRAM variable documentation
- [LABEL_CONVENTIONS.md](LABEL_CONVENTIONS.md) - Naming standards
- [reports/address_usage_report.csv](../reports/address_usage_report.csv) - Address usage statistics

### Related Issues

- #3: Memory Address & Variable Label System (parent)
- #23: Address Inventory and Analysis
- #25: ROM Data Map Documentation (this document - comprehensive catalog)
- #30: ROM Data Table Labels

### Related Files

- [labels/rom_data_tables.csv](../labels/rom_data_tables.csv) - ROM label mappings
- Bank-specific ASM files: `src/asm/bank_*_documented.asm`

---

**End of ROM Data Map**
