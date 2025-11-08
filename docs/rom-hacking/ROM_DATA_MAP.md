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
- **Banks:** 16 banks (Bank $00-$0f), each up to 64 KB
- **Address Range:** $8000-$ffff per bank (32 KB per half-bank)
- **Header:** LoROM mapping

---

## ROM Organization

### Bank Layout

| Bank | Range | Primary Content |
|------|-------|-----------------|
| $00 | $8000-$ffff | Main code, initialization |
| $01 | $8000-$ffff | Core game logic |
| $02 | $8000-$ffff | Battle system |
| $03 | $8000-$ffff | Map/field system |
| $04 | $8000-$ffff | Menu system |
| $05 | $8000-$ffff | Text engine |
| $06 | $8000-$ffff | Graphics routines |
| $07 | $8000-$ffff | Enemy/character data |
| $08 | $8000-$ffff | Item/equipment data |
| $09 | $8000-$ffff | Spell/ability data |
| $0a | $8000-$ffff | Graphics data |
| $0b | $8000-$ffff | Enemy graphics/data |
| $0c | $8000-$ffff | Map data |
| $0d | $8000-$ffff | Music/audio data |
| $0e | $8000-$ffff | Compressed graphics |
| $0f | $8000-$ffff | Additional data |

---

## Data Tables

### Character Data Tables (Bank $07)

Character stats, progression, and configuration data.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $07xxxx | CharacterStatsTable | ~256 B | Base character statistics |
| $07xxxx | CharacterProgressionTable | ~128 B | Level-up stat gains |
| $07xxxx | CharacterEquipmentTable | ~64 B | Equipment compatibility |

### Enemy Data Tables (Bank $07, $0b)

Enemy stats, AI, graphics pointers.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $07af3b | EnemyDataTable | Variable | Enemy data table pointers |
| $0b8892 | EnemyGraphicsPointerTable | ~106 B | Enemy graphics pointers (53 entries × 2 bytes) |
| $0b8cd9 | EnemyExtendedAttributesTable | Variable | Extended enemy attributes |

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
+$0a    1     AI pattern
+$0b    1     Special flags
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

### Graphics Data (Banks $0a, $0b, $0e)

Compressed and uncompressed graphics data.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $0axxxx | TileDataCompressed | Variable | Compressed tile graphics |
| $0axxxx | SpriteDataCompressed | Variable | Compressed sprite graphics |
| $0bxxxx | EnemySpriteGraphics | Variable | Enemy sprite pixel data |
| $0exxxx | BackgroundGraphics | Variable | Background/tileset graphics |

### Pointer Tables

Tables containing addresses of data structures.

| Address | Label | Entries | Description |
|---------|-------|---------|-------------|
| $07af3b | EnemyDataPointers | 53 | Pointers to enemy data structures |
| $0b8892 | EnemyGraphicsPointers | 53 | Pointers to enemy graphics |
| $0d9c3c | MusicTrackPointers | 8 | Music track data pointers |

### Audio/Music Tables (Bank $0d)

Music tracks, sound effects, and audio configuration.

| Address | Label | Size | Description |
|---------|-------|------|-------------|
| $0d9c3c | MusicTrackPointerTable | 16 B | Music track pointers (8 tracks) |
| $0d9cfc | AudioConfigTable | 16 B | Audio timing/buffer config |
| $0d9d78 | TrackDataBlock0 | Variable | Music track data block 0 |
| $0dbdff | MusicBankTable | Variable | Bank bytes for music tracks |
| $0dbe00 | MusicAddressTableLo | Variable | Music address low bytes |
| $0dbe35 | MusicTrackSizes | 16 B | Track size table (8 tracks) |
| $0dbe59 | MusicTrackFlags | 16 B | Track flags (8 tracks) |
| $0dbe7d | ADSRValuesTable | 16 B | ADSR envelope values (8 tracks) |

---

## Subroutines

Common ROM subroutines called frequently throughout the game.

### Graphics Routines

| Address | Label | Usage | Purpose |
|---------|-------|-------|---------|
| $fc8e | GraphicsDecompression | 8× | Decompress graphics data |
| $ab5c | SpriteUpdate | 6× | Update sprite positions/attributes |
| $fd50 | VRAMTransfer | 6× | Transfer data to VRAM |
| $81db | LoadTilemap | 2× | Load tilemap data |
| $8672 | RenderTiles | 2× | Render tiles to buffer |
| $84e0 | ProcessSprites | 2× | Process sprite data |
| $8b75 | UpdateAnimation | 2× | Update animation frames |
| $8b82 | SetAnimationState | 2× | Set animation state |

### System Routines

| Address | Label | Usage | Purpose |
|---------|-------|-------|---------|
| $8e06 | InitGraphicsEngine | 2× | Initialize graphics system |
| $82cf | SetupDMA | 2× | Configure DMA transfer |
| $94cc | MenuGraphics | 2× | Menu rendering routines |
| $9fae | BattleGraphics | 2× | Battle scene rendering |

### Data Loading

| Address | Label | Usage | Purpose |
|---------|-------|-------|---------|
| $a08a | LoadEnemySprite | 2× | Load enemy sprite graphics |
| $a403 | LoadCharacterSprite | 2× | Load character sprite |

### Lookup Tables

| Address | Label | Type | Purpose |
|---------|-------|------|---------|
| $f280 | TileDataTable | Data | Tile data lookup (4 uses) |
| $839e | PaletteDataLo | Data | Palette data (low byte) |
| $839f | PaletteDataHi | Data | Palette data (high byte) |
| $88c4 | OffsetTableLo | Data | Offset table (low byte) |
| $88c5 | OffsetTableHi | Data | Offset table (high byte) |

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
- Enemy stats ($07af3b)
- Battle formations
- Encounter tables

### Bank $0b: Enemy Graphics & Data

Enemy sprite graphics and extended attributes.

**Key Data:**
- Enemy graphics pointers ($0b8892)
- Enemy sprite configuration
- Enemy sprite tile tables
- Enemy graphics pixel data
- Enemy extended attributes ($0b8cd9)

### Bank $0d: Audio System

Music and sound effect data.

**Key Data:**
- Music track pointers ($0d9c3c)
- Audio configuration ($0d9cfc)
- Track data blocks ($0d9d78+)
- Music bank/address tables ($0dbdff+)
- Track sizes, flags, ADSR values

### Bank $0e: Compressed Graphics

Compressed tileset and background graphics.

---

## Complete Data Table Catalog

This section lists all 296 DATA8/DATA16/ADDR labels found across all documented banks. Generated by `tools/catalog_rom_data.ps1`.

### Catalog Statistics

- **Total Tables:** 296 (295 DATA8, 1 DATA16)
- **Banks Documented:** 13 of 16 (Banks $00-$02, $04-$0d)
- **Primary Data Banks:** $07 (77 tables), $02 (64 tables), $01 (43 tables)

### Bank-by-Bank Listing

#### Bank $00: System & Initialization (23 tables)

Tables related to system initialization, interrupt handling, and core routines.

| Address | Label | Description |
|---------|-------|-------------|
| $0081d5 | DATA8_0081D5 | |
| $0081d6 | DATA8_0081D6 | |
| $0081d8 | DATA8_0081D8 | |
| $0081d9 | DATA8_0081D9 | |
| $0081db | DATA8_0081DB | |
| $0081ed | DATA8_0081ED | |
| $00822a | DATA8_00822A | |
| $00822d | DATA8_00822D | |
| $008252 | DATA8_008252 | |
| $008334 | DATA8_008334 | |
| $008960 | DATA8_008960 | |
| $008961 | DATA8_008961 | |
| $008962 | DATA8_008962 | |
| $0097fb | DATA8_0097FB | |
| $009a1e | DATA8_009A1E | |
| $009c87 | DATA8_009C87 | |
| $009e0e | DATA8_009E0E | |
| $009e6e | DATA8_009E6E | |
| $00a2dd | DATA8_00A2DD | |
| $00a2de | DATA8_00A2DE | |
| $00c339 | DATA8_00C339 | |
| $00c33a | DATA8_00C33A | |
| $00c33b | DATA8_00C33B | |

#### Bank $01: Core Game Logic (43 tables)

Core gameplay systems, state management, and game flow control.

<details>
<summary>Show all Bank $01 tables (43 entries)</summary>

| Address | Label | Description |
|---------|-------|-------------|
| $018000 | DATA8_018000 | |
| $018032 | DATA8_018032 | |
| $018242 | DATA8_018242 | |
| $0182fe | DATA8_0182FE | |
| $01832f | DATA8_01832F | |
| $018330 | DATA8_018330 | |
| $01835b | DATA8_01835B | |
| $01839f | DATA8_01839F | |
| $0183a0 | DATA8_0183A0 | |
| $0183a2 | DATA8_0183A2 | |
| $018557 | DATA8_018557 | |
| $01a5e0 | DATA8_01A5E0 | |
| $01a63a | DATA8_01A63A | |
| $01a63c | DATA8_01A63C | |
| $01abf9 | DATA8_01ABF9 | |
| $01b1fb | DATA8_01B1FB | |
| $01b23b | DATA8_01B23B | |
| $01b277 | DATA8_01B277 | |
| $01b2c2 | DATA8_01B2C2 | |
| $01b311 | DATA8_01B311 | |
| $01b365 | DATA8_01B365 | |
| $01b3b8 | DATA8_01B3B8 | |
| $01b40e | DATA8_01B40E | |
| $01b45d | DATA8_01B45D | |
| $01b4ac | DATA8_01B4AC | |
| $01b4ff | DATA8_01B4FF | |
| $01b551 | DATA8_01B551 | |
| $01b595 | DATA8_01B595 | |
| $01b5cd | DATA8_01B5CD | |
| $01b606 | DATA8_01B606 | |
| $01b649 | DATA8_01B649 | |
| $01b697 | DATA8_01B697 | |
| $01b6d1 | DATA8_01B6D1 | |
| $01b709 | DATA8_01B709 | |
| $01b74d | DATA8_01B74D | |
| $01b79c | DATA8_01B79C | |
| $01b7e4 | DATA8_01B7E4 | |
| $01b841 | DATA8_01B841 | |
| $01b89e | DATA8_01B89E | |
| $01b8f0 | DATA8_01B8F0 | |
| $01b944 | DATA8_01B944 | |
| $01bed6 | DATA8_01BED6 | |
| $01c0d1 | DATA8_01C0D1 | |

</details>

#### Bank $02: Battle System (64 tables)

Battle mechanics, damage calculation, enemy AI, and combat animations.

<details>
<summary>Show all Bank $02 tables (64 entries)</summary>

| Address | Label | Description |
|---------|-------|-------------|
| $029ba0 | DATA8_029BA0 | |
| $02a272 | DATA8_02A272 | |
| $02a273 | DATA8_02A273 | |
| $02a278 | DATA8_02A278 | |
| $02a279 | DATA8_02A279 | |
| $02aa79 | DATA8_02AA79 | |
| $02aab9 | DATA8_02AAB9 | |
| $02aabd | DATA8_02AABD | |
| $02aac1 | DATA8_02AAC1 | |
| $02aac5 | DATA8_02AAC5 | |
| $02ac53 | DATA8_02AC53 | |
| $02ac93 | DATA8_02AC93 | |
| $02ac97 | DATA8_02AC97 | |
| $02ac9b | DATA8_02AC9B | |
| $02ac9f | DATA8_02AC9F | |
| $02d3e7 | DATA8_02D3E7 | |
| $02d3ed | DATA8_02D3ED | |
| $02d58f | DATA8_02D58F | |
| $02d627 | DATA8_02D627 | |
| $02d72b | DATA8_02D72B | |
| $02d77a | DATA8_02D77A | |
| $02d7d3 | DATA8_02D7D3 | |
| $02d8bf | DATA8_02D8BF | |
| $02d96c | DATA8_02D96C | |
| $02d96e | DATA8_02D96E | |
| $02d970 | DATA8_02D970 | |
| $02d972 | DATA8_02D972 | |
| $02d974 | DATA8_02D974 | |
| $02da7d | DATA8_02DA7D | |
| $02db83 | DATA8_02DB83 | |
| $02dcc4 | DATA8_02DCC4 | |
| $02dd30 | DATA8_02DD30 | |
| $02df53 | DATA8_02DF53 | |
| $02dfbe | DATA8_02DFBE | |
| $02e34c | DATA8_02E34C | |
| $02e34e | DATA8_02E34E | |
| $02e5bb | DATA8_02E5BB | |
| $02e5c0 | DATA8_02E5C0 | |
| $02e5c5 | DATA8_02E5C5 | |
| $02e5ca | DATA8_02E5CA | |
| $02e5cf | DATA8_02E5CF | |
| $02e5d4 | DATA8_02E5D4 | |
| $02e5d9 | DATA8_02E5D9 | |
| $02e5de | DATA8_02E5DE | |
| $02e5e3 | DATA8_02E5E3 | |
| $02e5e8 | DATA8_02E5E8 | |
| $02ead7 | DATA8_02EAD7 | |
| $02eadc | DATA8_02EADC | |
| $02eae1 | DATA8_02EAE1 | |
| $02eae6 | DATA8_02EAE6 | |
| $02eaeb | DATA8_02EAEB | |
| $02eaf0 | DATA8_02EAF0 | |
| $02eaf5 | DATA8_02EAF5 | |
| $02eafa | DATA8_02EAFA | |
| $02eaff | DATA8_02EAFF | |
| $02eb04 | DATA8_02EB04 | |
| $02fc50 | DATA8_02FC50 | |
| $02fc51 | DATA8_02FC51 | |
| $02fc53 | DATA8_02FC53 | |
| $02fc54 | DATA8_02FC54 | |
| $02fc55 | DATA8_02FC55 | |
| $02fc56 | DATA8_02FC56 | |
| $02fc57 | DATA8_02FC57 | |
| $02fd8f | DATA8_02FD8F | |

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
| $058a80 | DATA8_058A80 | |

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
| $07800a | DATA8_07800A | |
| $07800c | DATA8_07800C | |
| $078030 | DATA8_078030 | |
| $078031 | DATA8_078031 | |
| $0790bb | DATA8_0790BB | |
| $07af3b | DATA8_07AF3B | Enemy Data Pointers |
| $07b013 | DATA8_07B013 | |
| $07d7f4 | DATA8_07D7F4 | |
| $07d7f5 | DATA8_07D7F5 | |
| $07d7f6 | DATA8_07D7F6 | |
| $07d7f7 | DATA8_07D7F7 | |
| $07d7f8 | DATA8_07D7F8 | |
| $07d7f9 | DATA8_07D7F9 | |
| $07d7fa | DATA8_07D7FA | |
| $07d7fb | DATA8_07D7FB | |
| $07d7fc | DATA8_07D7FC | |
| $07d7fd | DATA8_07D7FD | |
| $07d7fe | DATA8_07D7FE | |
| $07d7ff | DATA8_07D7FF | |
| $07d800 | DATA8_07D800 | |
| $07d801 | DATA8_07D801 | |
| $07d802 | DATA8_07D802 | |
| $07d803 | DATA8_07D803 | |
| $07d814 | DATA8_07D814 | |
| $07d815 | DATA8_07D815 | |
| $07d816 | DATA8_07D816 | |
| $07d817 | DATA8_07D817 | |
| $07d818 | DATA8_07D818 | |
| $07d819 | DATA8_07D819 | |
| $07d81a | DATA8_07D81A | |
| $07d81b | DATA8_07D81B | |
| $07d81c | DATA8_07D81C | |
| $07d81d | DATA8_07D81D | |
| $07d81e | DATA8_07D81E | |
| $07d81f | DATA8_07D81F | |
| $07d820 | DATA8_07D820 | |
| $07d821 | DATA8_07D821 | |
| $07d822 | DATA8_07D822 | |
| $07d823 | DATA8_07D823 | |
| $07d824 | DATA8_07D824 | |
| $07d8e4 | DATA8_07D8E4 | |
| $07d8e5 | DATA8_07D8E5 | |
| $07d8e6 | DATA8_07D8E6 | |
| $07d8e7 | DATA8_07D8E7 | |
| $07d8e8 | DATA8_07D8E8 | |
| $07d8e9 | DATA8_07D8E9 | |
| $07d8ea | DATA8_07D8EA | |
| $07d8eb | DATA8_07D8EB | |
| $07d8ec | DATA8_07D8EC | |
| $07d8ed | DATA8_07D8ED | |
| $07d8ee | DATA8_07D8EE | |
| $07d8ef | DATA8_07D8EF | |
| $07d8f0 | DATA8_07D8F0 | |
| $07d8f1 | DATA8_07D8F1 | |
| $07d8f2 | DATA8_07D8F2 | |
| $07d8f3 | DATA8_07D8F3 | |
| $07db14 | DATA8_07DB14 | |
| $07eb44 | DATA8_07EB44 | |
| $07eb45 | DATA8_07EB45 | |
| $07eb46 | DATA8_07EB46 | |
| $07eb47 | DATA8_07EB47 | |
| $07eb48 | DATA8_07EB48 | |
| $07ee84 | DATA8_07EE84 | |
| $07ee85 | DATA8_07EE85 | |
| $07ee86 | DATA8_07EE86 | |
| $07ee87 | DATA8_07EE87 | |
| $07ee88 | DATA8_07EE88 | |
| $07efa1 | DATA8_07EFA1 | |
| $07f011 | DATA8_07F011 | |

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

#### Bank $0a: Graphics Data (2 tables)

Compressed tile and sprite graphics.

| Address | Label | Description |
|---------|-------|-------------|
| $0a8000 | DATA8_0A8000 | |
| $0a830c | DATA8_0A830C | |

#### Bank $0b: Enemy Graphics & Animation (35 tables)

Enemy sprite data, animation handlers, and graphics pointers.

| Address | Label | Description |
|---------|-------|-------------|
| $0b8140 | DATA8_0B8140 | |
| $0b8296 | DATA8_0B8296 | |
| $0b829e | DATA8_0B829E | |
| $0b829f | DATA8_0B829F | |
| $0b82a0 | DATA8_0B82A0 | |
| $0b8324 | DATA8_0B8324 | |
| $0b83ac | DATA8_0B83AC | |
| $0b83ad | DATA8_0B83AD | |
| $0b83b2 | DATA8_0B83B2 | |
| $0b844f | DATA8_0B844F | |
| $0b8450 | DATA8_0B8450 | |
| $0b8451 | DATA8_0B8451 | |
| $0b8452 | DATA8_0B8452 | |
| $0b8497 | DATA8_0B8497 | |
| $0b84df | DATA8_0B84DF | |
| $0b84e0 | DATA8_0B84E0 | |
| $0b84e1 | DATA8_0B84E1 | |
| $0b84e2 | DATA8_0B84E2 | |
| $0b856c | DATA8_0B856C | |
| $0b8659 | DATA8_0B8659 | |
| $0b865b | DATA8_0B865B | |
| $0b8735 | DATA8_0B8735 | |
| $0b8737 | DATA8_0B8737 | |
| $0b87e4 | DATA8_0B87E4 | |
| $0b87e5 | DATA8_0B87E5 | |
| $0b8892 | DATA8_0B8892 | Enemy Graphics Pointer Table |
| $0b88fc | DATA8_0B88FC | |
| $0b8cd9 | DATA8_0B8CD9 | Enemy Extended Attributes Table |
| $0b8f03 | DATA8_0B8F03 | Same-state animation handlers |
| $0b8f15 | DATA8_0B8F15 | Changed-state animation handlers |
| $0b905f | DATA8_0B905F | Rotation frame handlers |
| $0b9113 | DATA8_0B9113 | 4-frame tile pattern handlers |
| $0b91d0 | DATA8_0B91D0 | Attack motion frames |
| $0bf08f | DATA8_0BF08F | |
| $0bf091 | DATA8_0BF091 | |

#### Bank $0c: Map/World Data (10 tables)

World map, collision, and map-related tables.

| Address | Label | Description |
|---------|-------|-------------|
| $0c8659 | DATA8_0C8659 | |
| $0c886b | DATA8_0C886B | |
| $0c88b0 | DATA8_0C88B0 | |
| $0c8b66 | DATA16_0C8B66 | Sine/cosine table 1 (48 entries) |
| $0c8b93 | DATA8_0C8B93 | Animation speed table (30 bytes) |
| $0c8c5e | DATA8_0C8C5E | |
| $0c8cde | DATA8_0C8CDE | |
| $0c8d1e | DATA8_0C8D1E | |
| $0cef85 | DATA8_0CEF85 | |
| $0cef89 | DATA8_0CEF89 | |

#### Bank $0d: Music/Audio System (23 tables)

Music track data, sound effects, and audio engine tables.

| Address | Label | Description |
|---------|-------|-------------|
| $0d8008 | DATA8_0D8008 | |
| $0d8009 | DATA8_0D8009 | |
| $0d8014 | DATA8_0D8014 | |
| $0d8015 | DATA8_0D8015 | |
| $0d9c3c | DATA8_0D9C3C | Track pointers 0-7 |
| $0d9cfc | DATA8_0D9CFC | Config: Timing/buffers |
| $0d9d78 | DATA8_0D9D78 | Track data block 0 |
| $0dbdff | DATA8_0DBDFF | Bank byte for entry 0 |
| $0dbe00 | DATA8_0DBE00 | Address low byte |
| $0dbe01 | DATA8_0DBE01 | Music track pointers 0-5 |
| $0dbe35 | DATA8_0DBE35 | Track sizes 0-7 |
| $0dbe59 | DATA8_0DBE59 | Track flags 0-7 |
| $0dbe7d | DATA8_0DBE7D | ADSR values 0-7 |
| $0dc451 | DATA8_0DC451 | |
| $0dc821 | DATA8_0DC821 | |
| $0dcc31 | DATA8_0DCC31 | |
| $0ddd51 | DATA8_0DDD51 | |
| $0ddfc1 | DATA8_0DDFC1 | |
| $0de431 | DATA8_0DE431 | |

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
