# Final Fantasy Mystic Quest - SNES Disassembly & ROM Hack Project

> **🤖 Automatic Logging Active:** Just run `.\start-tracking.ps1` once and all your work is logged automatically!  
> No manual logging needed - the system tracks everything for you in the background.

A comprehensive disassembly and development environment for Final Fantasy Mystic Quest (SNES) using modern tools and practices.

## Project Overview

This project provides:
- **✅ Complete disassembly** of Final Fantasy Mystic Quest (100% coverage via Diztinguish)
- **✅ 80,973 lines** of integrated source code from multiple sources
- **✅ Modern SNES development** environment using ca65/asar
- **✅ Complete graphics toolchain** (extraction, conversion, PNG support)
- **✅ Asset extraction tools** (graphics, text, data)
- **✅ Comprehensive documentation** of game mechanics and data structures
- **✅ Professional build system** with automated scripts
- **✅ Integration with MesenS** emulator for testing

### Recent Achievements (2025-10-24)

🎉 **Major Integration Complete!** Successfully integrated all historical disassembly work:
- **18 Diztinguish files**: Complete ROM coverage (bank_00 through bank_0F)
- **Detailed engines**: Text rendering and graphics loading systems with extensive comments
- **All game data**: Character stats, text data, graphics binaries
- **Build infrastructure**: PowerShell scripts, documentation, unified assembly
- **44 files added** in single integration session
- See [integration-complete.md](docs/integration-complete.md) for full details

## Project Structure

```
ffmq-info/
├── src/                    # Source code (✅ Complete integration!)
│   ├── asm/               # Assembly source files
│   │   ├── banks/         # 18 Diztinguish disassembly files (80K+ lines)
│   │   │   ├── bank_00.asm   # 14,018 lines - Main initialization
│   │   │   ├── bank_01.asm   # Additional engine code
│   │   │   ├── ...           # Banks 02-0E
│   │   │   ├── bank_0F.asm   # Additional code
│   │   │   ├── labels.asm    # SNES register definitions
│   │   │   └── main.asm      # Diztinguish main file
│   │   ├── ffmq_complete.asm # Master assembly file (integrates everything)
│   │   ├── text_engine.asm   # Text rendering (detailed comments)
│   │   ├── graphics_engine.asm # Graphics loading (detailed comments)
│   │   └── README.md         # Source documentation
│   ├── include/           # Include files (constants, macros)
│   │   ├── ffmq_macros_original.inc  # 8 assembly macros
│   │   ├── ffmq_ram_variables.inc    # RAM variable definitions
│   │   ├── snes_registers.inc        # Hardware registers
│   │   └── ffmq_constants.inc        # Game constants
│   ├── data/              # Data files (tables, text, stats)
│   │   ├── text/          # 11 text data files + character table
│   │   └── character-start-stats.asm
│   └── graphics/          # Binary graphics data (5 files)
├── assets/                # Extracted game assets (PNG conversions)
│   ├── graphics/          # Graphics files (PNG, etc.)
│   ├── text/              # Text files
│   └── music/             # Music files
├── tools/                 # Development tools (✅ Complete graphics suite!)
│   ├── snes_graphics.py   # SNES tile/palette codec (450 lines)
│   ├── convert_graphics.py # PNG conversion (440 lines)
│   ├── extract_graphics_v2.py # ROM extraction (370 lines)
│   └── build_tools/       # Build utilities
├── build/                 # Build output directory
├── docs/                  # Documentation (✅ Comprehensive!)
│   ├── graphics-format.md    # SNES graphics reference (600 lines)
│   ├── graphics-quickstart.md # Quick start guide (400 lines)
│   ├── build-instructions.md  # Build system documentation
│   └── integration-complete.md # Integration summary
├── historical/            # Original project files (archived)
│   ├── original-code/     # Original assembly files (SOURCE)
│   ├── diztinguish-disassembly/ # Diztinguish output (SOURCE)
│   └── tools/             # Original tools
├── build.ps1              # Professional build script
├── log.ps1                # Automatic chat logging
├── track.ps1              # File change tracking
└── ~roms/                 # ROM files (not in git)
```

## Requirements

### Essential Tools
- **ca65/cc65**: 65816 assembler and toolchain
	- Download: https://cc65.github.io/
	- Used for modern assembly development
- **asar**: SNES assembler (alternative/compatibility)
	- Download: https://github.com/RPGHacker/asar
	- Used for SNES-specific features
- **Python 3.x**: For development tools and scripts
	- Download: https://python.org/

### Optional Tools
- **MesenS**: SNES emulator with debugging features
	- Download: https://github.com/SourMesen/Mesen-S
	- Used for testing and debugging
- **YY-CHR**: Graphics editor for SNES graphics
- **Hex Editor**: For manual ROM inspection

### ROM Requirements
Place your ROM files in the `~roms/` directory:
- `Final Fantasy - Mystic Quest (U) (V1.1).sfc` (primary development ROM)
- Other regional versions for comparison (optional)

## Quick Start

### 1. Setup Environment
```powershell
# The project includes everything needed for assembly!
# Just need to install asar to build

# Download asar from: https://github.com/RPGHacker/asar/releases
# Extract asar.exe to project root or add to PATH
```

### 2. Build ROM (Using Integrated Source)
```powershell
# Build from the complete integrated source code
.\build.ps1

# Or with verbose output
.\build.ps1 -Verbose

# Or generate symbol file for debugging
.\build.ps1 -Symbols

# Output will be in build/ffmq-rebuilt.sfc
```

### 3. Extract Graphics (Already Available!)
```bash
# Extract graphics from ROM to PNG
python tools/extract_graphics_v2.py ~roms/Final\ Fantasy\ -\ Mystic\ Quest\ \(U\)\ \(V1.1\).sfc

# Convert individual graphics
python tools/convert_graphics.py to-png input.bin output.png --format 4bpp

# Convert back to SNES format
python tools/convert_graphics.py to-snes input.png output.bin --format 4bpp
```

### 4. Test ROM
```bash
# Test in MesenS emulator (if installed)
mesen build/ffmq-rebuilt.sfc
```

## Development Workflow

### Code Formatting Standards

**All assembly code follows standardized formatting for consistency:**

- **Line Endings**: CRLF (Windows standard)
- **Encoding**: UTF-8 with BOM
- **Indentation**: Tabs (4-space equivalent)
- **Column Alignment**: Labels (0), Opcodes (23), Operands (47), Comments (57)

#### Format ASM Files

```powershell
# Preview formatting changes (dry-run)
.\tools\format_asm.ps1 -Path src\asm\bank_00_documented.asm -DryRun

# Apply formatting
.\tools\format_asm.ps1 -Path src\asm\bank_00_documented.asm

# Format multiple files
Get-ChildItem src\asm\bank_*.asm | ForEach-Object {
    .\tools\format_asm.ps1 -Path $_.FullName
}
```

#### VS Code Tasks

Use built-in tasks for quick formatting:
- **Ctrl+Shift+P** → "✨ Format ASM File" (applies formatting)
- **Ctrl+Shift+P** → "🔍 Verify ASM Formatting" (preview only)

See [CONTRIBUTING.md](CONTRIBUTING.md) for complete formatting guidelines.

### Modifying Code
1. Edit assembly files in `src/asm/`
2. Update constants in `src/include/ffmq_constants.inc`
3. Add new macros to `src/include/ffmq_macros.inc`
4. Build and test: `make rom && make test`

### Modifying Graphics
1. Extract original graphics: `make extract-assets`
2. Edit graphics files in `assets/graphics/`
3. Use tools to convert back to SNES format
4. Rebuild ROM and test

### Modifying Text
1. Extract text: `make extract-assets`
2. Edit text files in `assets/text/`
3. Use text tools to reinsert into ROM
4. Rebuild and test

## Documentation

📚 **[Complete Documentation Index](docs/README.md)** - Start here for organized access to all documentation!

### Quick Links

**Getting Started:**
- **[BUILD_GUIDE.md](docs/BUILD_GUIDE.md)** ⭐ - Comprehensive build instructions and troubleshooting
- **[MODDING_GUIDE.md](docs/MODDING_GUIDE.md)** ⭐ - Complete guide to creating game modifications
- **[CONTRIBUTING.md](CONTRIBUTING.md)** ⭐ - How to contribute to the project

**Technical Reference:**
- **[Integration Complete](docs/integration-complete.md)** - Complete integration summary (300 lines)
- **[Source Code README](src/asm/README.md)** - Source organization and structure
- **[Graphics Format](docs/graphics-format.md)** - SNES graphics format (600 lines)
- **[Data Formats](docs/data_formats.md)** - Game data structures and formats

**Tools & Build System:**
- **[Build Instructions](docs/build-instructions.md)** - Quick build reference
- **[Graphics Quick Start](docs/graphics-quickstart.md)** - Graphics tools guide (400 lines)
- **[Testing Guide](docs/testing.md)** - Testing framework and procedures

### All Documentation

See **[docs/README.md](docs/README.md)** for the complete, categorized documentation index with recommended reading orders for contributors, modders, and researchers.

### Implementation Status

✅ **Complete**
- [x] Graphics tools (Python suite with PNG conversion)
- [x] Source code integration (80,973 lines from Diztinguish + historical)
- [x] Build system (PowerShell scripts, asar support)
- [x] Comprehensive documentation
- [x] Automatic change tracking and logging
- [x] Project organization and structure

🔄 **In Progress**
- [ ] First build attempt (need asar installed)
- [ ] Build verification and testing
- [ ] ROM matching verification

⏳ **Planned**
- [ ] Text extraction/insertion tools
- [ ] ca65 syntax conversion
- [ ] Music/sound tools
- [ ] Additional game mechanics documentation

## Data Sources

This project is based on extensive research and documentation:
- **DataCrystal Wiki**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest
- **GameInfo Repository**: https://github.com/TheAnsarya/GameInfo/tree/main/Final%20Fantasy%20Mystic%20Quest%20(SNES)
- **Diztinguish Disassembly**: Advanced disassembly tool output
- **Community Research**: SNES homebrew and ROM hacking community

## Historical Files

The `historical/` directory contains the original project files:
- Original assembly attempts using asar
- Diztinguish disassembly output
- Asset extraction tools (C#)
- Testing frameworks

These are preserved for reference but the modern development should use the new structure.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the coding standards
4. Test thoroughly with `make test`
5. Document your changes
6. Submit a pull request

### Coding Standards
- Use meaningful labels and comments
- Follow the existing macro conventions
- Document new constants and data structures
- Test all changes with the emulator

## Known ROM Versions

| ROM | CRC32 | MD5 | Notes |
|-----|-------|-----|-------|
| Final Fantasy - Mystic Quest (U) (V1.1) | 2c52c792 | f7faeae5a847c098d677070920769ca2 | Primary development target |
| Final Fantasy - Mystic Quest (U) (V1.0) | 6b19a2c6 | da08f0559fade06f37d5fdf1b6a6d92e | Original US release |
| Final Fantasy USA - Mystic Quest (J) | 1da17f0c | 5164060bd3350d7a6325ec8ae80bba54 | Japanese version |
| Mystic Quest Legend (E) | 45a7328f | 92461cd3f1a72b8beb32ebab98057b76 | European version |

## Legal Notice

This project is for educational and preservation purposes. You must own a legal copy of Final Fantasy Mystic Quest to use these tools. This project does not distribute copyrighted ROM files.

## Legacy Setup (Historical)
**Note: The following is preserved for reference but modern development should use the new build system above.**

### Original asar setup
asar - <https://www.smwcentral.net/?p=section&a=details&id=19043>

put somewhere like C:\asar\ 

and add that folder to your environment path
