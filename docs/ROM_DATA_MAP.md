# FFMQ ROM Data Map

**Last Updated:** November 1, 2025  
**Related Issues:** #30, #3  
**Related Files:** `labels/rom_data_tables.csv`

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

## Cross-References

### Related Documents

- [RAM_MAP.md](RAM_MAP.md) - WRAM variable documentation
- [LABEL_CONVENTIONS.md](LABEL_CONVENTIONS.md) - Naming standards
- [reports/address_usage_report.csv](../reports/address_usage_report.csv) - Address usage statistics

### Related Issues

- #3: Memory Address & Variable Label System (parent)
- #23: Address Inventory and Analysis
- #30: ROM Data Table Labels (this document)

### Related Files

- [labels/rom_data_tables.csv](../labels/rom_data_tables.csv) - ROM label mappings
- Bank-specific ASM files: `src/asm/bank_*_documented.asm`

---

**End of ROM Data Map**
