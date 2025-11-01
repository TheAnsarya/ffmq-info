# FFMQ Complete Disassembly Integration

This directory contains the complete integrated disassembly of Final Fantasy Mystic Quest (SNES).

## Source Integration

### 1. Diztinguish Full Disassembly

**Location:** `banks/` (18 files)

The complete Diztinguish disassembly provides 100% code coverage of the game:

- `bank_00.asm` through `bank_0F.asm` - All 16 ROM banks
- `labels.asm` - SNES hardware register definitions and global labels
- `main.asm` - Original Diztinguish main file (included all banks)

**Coverage:**
- ~14,000+ lines per major bank (bank_00.asm has 14,018 lines)
- Complete code disassembly with mnemonics
- All data sections marked
- SNES register references
- Jump targets and subroutines labeled

### 2. Original Reverse Engineering Work

**Location:** Various files

Detailed reverse-engineered and commented routines:

#### Core Engines

- **`text_engine.asm`** - Text rendering system
  - Character display routines
  - Text box management
  - Dialogue system
  - Compressed text loading
  - Detailed comments explaining each routine

- **`graphics_engine.asm`** - Graphics loading system
  - Tile DMA transfers
  - Palette management
  - VRAM organization
  - Background layer setup
  - Detailed routine documentation

#### Macros and Definitions

- **`../include/ffmq_macros_original.inc`** - Assembly macros
  - `%setAto8bit()` / `%setAto16bit()` - Register size control
  - `%setXYto8bit()` / `%setXYto16bit()` - Index register sizing
  - `%setAXYto8bit()` / `%setAXYto16bit()` - Combined sizing
  - `%setDatabank()` / `%setDatabankA()` - Bank management
  - `pctosnes()` macro for address conversion

- **`../include/ffmq_ram_variables.inc`** - RAM variable definitions
  - All game RAM addresses
  - Variable names and purposes
  - Memory layout documentation

### 3. Game Data

**Location:** `../data/`

#### Text Data (`../data/text/`)

All game text organized by category:

- `weapon-names.asm` - All weapon names
- `armor-names.asm` - All armor names
- `helmet-names.asm` - All helmet names
- `shield-names.asm` - All shield names
- `accessory-names.asm` - All accessory names
- `item-names.asm` - All consumable item names
- `spell-names.asm` - All magic spell names
- `attack-descriptions.asm` - Attack/spell descriptions
- `location-names.asm` - All location names
- `monster-names.asm` - All enemy names
- `character-table.tbl` - Character encoding table

#### Character Data

- `character-start-stats.asm` - Starting stats for all characters

## File Organization

```
src/asm/
├── ffmq_complete.asm          # Main unified assembly file
├── text_engine.asm            # Text rendering engine (commented)
├── graphics_engine.asm        # Graphics loading engine (commented)
├── init.s                     # Modern initialization (ca65)
├── main.s                     # Modern main file (ca65)
└── banks/                     # Diztinguish disassembly
    ├── bank_00.asm            # Bank $00 (14,018 lines)
    ├── bank_01.asm            # Bank $01
    ├── bank_02.asm            # Bank $02
    ├── ...                    # Banks $03-$0E
    ├── bank_0F.asm            # Bank $0F
    ├── labels.asm             # Global labels and constants
    └── main.asm               # Diztinguish main file

src/include/
├── snes_registers.inc         # SNES hardware registers
├── ffmq_macros.inc            # Modern ca65 macros
├── ffmq_macros_original.inc   # Original asar/bass macros
├── ffmq_ram_variables.inc     # RAM variable definitions
├── ffmq_constants.inc         # Game constants
└── snes_header.inc            # ROM header

src/data/
├── character-start-stats.asm  # Character starting data
└── text/                      # All text data
    ├── weapon-names.asm
    ├── armor-names.asm
    ├── helmet-names.asm
    ├── shield-names.asm
    ├── accessory-names.asm
    ├── item-names.asm
    ├── spell-names.asm
    ├── attack-descriptions.asm
    ├── location-names.asm
    ├── monster-names.asm
    └── character-table.tbl
```

## Memory Map

### ROM Organization (LoROM)

| SNES Address | PC Address | Bank | Contents |
|--------------|------------|------|----------|
| $00:8000-$00:FFFF | $000000-$007FFF | $00 | Main initialization, core engine |
| $01:8000-$01:FFFF | $008000-$00FFFF | $01 | Additional engine code |
| $02:8000-$02:FFFF | $010000-$017FFF | $02 | Engine routines |
| $03:8000-$03:FFFF | $018000-$01FFFF | $03 | Game logic |
| $04:8000-$04:FFFF | $020000-$027FFF | $04 | Graphics data ($04:8000 tiles) |
| $05:8000-$05:FFFF | $028000-$02FFFF | $05 | Main tiles ($05:8C80) |
| $06:8000-$06:FFFF | $030000-$037FFF | $06 | Data and routines |
| $07:8000-$07:FFFF | $038000-$03FFFF | $07 | Palettes, sprite graphics ($07:B013) |
| $08:8000-$08:FFFF | $040000-$047FFF | $08 | Game data |
| $09:8000-$09:FFFF | $048000-$04FFFF | $09 | Battle system |
| $0A:8000-$0A:FFFF | $050000-$057FFF | $0A | Game logic |
| $0B:8000-$0B:FFFF | $058000-$05FFFF | $0B | Game logic |
| $0C:8000-$0C:FFFF | $060000-$067FFF | $0C | Menu system, UI, text |
| $0D:8000-$0D:FFFF | $068000-$06FFFF | $0D | Menu and UI |
| $0E:8000-$0E:FFFF | $070000-$077FFF | $0E | Additional systems |
| $0F:8000-$0F:FFFF | $078000-$07FFFF | $0F | Additional code |

### Key Data Locations

| Description | SNES Address | PC Address | File |
|-------------|--------------|------------|------|
| Main tiles | $05:8C80 | $028C80 | 34 banks of 4BPP tiles |
| Extra tiles | $04:8000 | $020000 | $100 tiles, 4BPP |
| Sprite graphics | $07:B013 | $03B013 | Character/enemy sprites |
| Palettes | $07:8000 | $038000 | Color palettes |
| Text data | $0C:xxxx | $06xxxx | Compressed dialogue |

## Build Instructions

### Option 1: asar (Current)

The code currently uses asar/bass syntax:

```bash
asar src/asm/ffmq_complete.asm output.sfc
```

### Option 2: ca65 (Future)

Will be converted to ca65 syntax:

```bash
make rom
```

## Integration Status

✅ **Complete**
- [x] Diztinguish disassembly copied (all 16 banks + labels)
- [x] Original macros integrated
- [x] RAM variables integrated
- [x] Text engine with detailed comments
- [x] Graphics engine with detailed comments
- [x] All text data (names, descriptions)
- [x] Character data
- [x] Unified main.asm created

🔄 **In Progress**
- [ ] Convert from asar syntax to ca65 syntax
- [ ] Generate missing graphics data files
- [ ] Create build system for unified assembly
- [ ] Test complete build

⏳ **Planned**
- [ ] Add more detailed comments to bank files
- [ ] Cross-reference routines between banks
- [ ] Document all data structures
- [ ] Create symbol maps for debugging

## Code Quality

### Diztinguish Disassembly
- ✅ Complete code coverage
- ✅ All instructions disassembled
- ✅ Jump targets labeled
- ✅ Register references marked
- ⚠️ Minimal comments (auto-generated)
- ⚠️ Generic labels (CODE_xxxxxx, DATA8_xxxxxx)

### Original Reverse Engineering
- ✅ Highly detailed comments
- ✅ Descriptive routine names
- ✅ Parameter documentation
- ✅ Return value documentation
- ✅ Algorithm explanations
- ✅ TODO notes for unclear sections

## Usage

### For Building ROMs

Use `ffmq_complete.asm` as the main file - it includes everything in the correct order.

### For Study/Research

- **Banks:** Start with `banks/bank_00.asm` for initialization code
- **Engines:** Read `text_engine.asm` and `graphics_engine.asm` for detailed algorithms
- **Data:** Check `../data/text/` for all game text

### For ROM Hacking

1. Modify the appropriate bank file or engine file
2. Rebuild with asar
3. Test in emulator
4. Document your changes

## Technical Notes

### Address Conversion

**PC to SNES (LoROM):**
```
PC Address:   $0x28C80
SNES Address: $05:8C80

Formula: SNES = ((PC >> 15) << 16) | (PC & $7FFF) | $8000
```

**SNES to PC (LoROM):**
```
SNES Address: $05:8C80  
PC Address:   $028C80

Formula: PC = ((SNES >> 16) << 15) | (SNES & $7FFF)
```

### Macro Reference

From `ffmq_macros_original.inc`:

```asm
%setAto8bit()          ; SEP #$20 - Set 8-bit accumulator
%setAto16bit()         ; REP #$20 - Set 16-bit accumulator  
%setXYto8bit()         ; SEP #$10 - Set 8-bit index registers
%setXYto16bit()        ; REP #$10 - Set 16-bit index registers
%setAXYto8bit()        ; SEP #$30 - Set all to 8-bit
%setAXYto16bit()       ; REP #$30 - Set all to 16-bit
%setDatabank(bank)     ; Set data bank register
%setDatabankA(bank)    ; Set data bank using A
```

## Resources

- **Diztinguish Project:** https://github.com/Dotsarecool/DiztinGUIsh
- **SNES Dev Wiki:** https://snesdev.mesen.ca/
- **65816 Reference:** http://www.6502.org/tutorials/65c816opcodes.html
- **LoROM Mapping:** https://en.wikibooks.org/wiki/Super_NES_Programming/SNES_memory_map

## Credits

- **Diztinguish Disassembly:** Auto-generated complete disassembly
- **Original Reverse Engineering:** Manual analysis and commenting
- **Integration:** Modern development structure and organization
- **Tools:** Diztinguish, asar, ca65, MesenS

---

*Last Updated: 2025-10-24*
*Status: Complete source integration, ready for build system development*
