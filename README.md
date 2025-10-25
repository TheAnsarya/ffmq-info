# Final Fantasy Mystic Quest - SNES Disassembly & ROM Hack Project

A comprehensive disassembly and development environment for Final Fantasy Mystic Quest (SNES) using modern tools and practices.

## Project Overview

This project provides:
- Complete disassembly of Final Fantasy Mystic Quest
- Modern SNES development environment using ca65/asar
- Asset extraction and editing tools (graphics, text, music)
- Documentation of game mechanics and data structures
- Build system for creating ROM hacks
- Integration with MesenS emulator for testing

## Project Structure

```
ffmq-info/
├── src/                    # Source code
│   ├── asm/               # Assembly source files
│   ├── include/           # Include files (constants, macros)
│   └── data/              # Data files (tables, graphics)
├── assets/                # Extracted game assets
│   ├── graphics/          # Graphics files (PNG, etc.)
│   ├── text/              # Text files
│   └── music/             # Music files
├── tools/                 # Development tools
│   ├── extract_*.py       # Asset extraction scripts
│   └── build_tools/       # Build utilities
├── build/                 # Build output directory
├── docs/                  # Documentation
├── historical/            # Original project files (archived)
│   ├── original-code/     # Original assembly files
│   ├── diztinguish-disassembly/ # Diztinguish output
│   └── tools/             # Original tools
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
```bash
# Check if required tools are installed
make setup-env

# If tools are missing, follow installation instructions
make install-tools
```

### 2. Extract Assets
```bash
# Extract graphics, text, and music from original ROM
make extract-assets
```

### 3. Build ROM
```bash
# Build the modified ROM
make rom

# Output will be in build/ffmq-modified.sfc
```

### 4. Test ROM
```bash
# Test in MesenS emulator (if installed)
make test
```

## Development Workflow

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

- **[ROM Map](docs/rom_map.md)**: Complete ROM memory layout
- **[RAM Map](docs/ram_map.md)**: RAM usage and variables
- **[Graphics Format](docs/graphics.md)**: SNES graphics format info
- **[Text Format](docs/text.md)**: Text encoding and compression
- **[Music Format](docs/music.md)**: Sound/music system
- **[Build System](docs/build.md)**: Detailed build instructions
- **[Tools Guide](docs/tools.md)**: Development tools reference

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