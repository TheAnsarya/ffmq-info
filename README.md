# Final Fantasy Mystic Quest - SNES Disassembly & ROM Hack Project

> **🚀 Quick Start:** Want to mod enemies? See [Modding Quick Reference](docs/guides/MODDING_QUICK_REFERENCE.md) for a 3-step guide!

> **🤖 Automatic Logging Active:** Just run `.\start-tracking.ps1` once and all your work is logged automatically!  
> No manual logging needed - the system tracks everything for you in the background.

> **📊 Project Management:** All issues and tasks are tracked in [GitHub Project #3](https://github.com/users/TheAnsarya/projects/3)

A comprehensive disassembly and ROM modding environment for Final Fantasy Mystic Quest (SNES) with a complete battle data editing pipeline.

## ✨ What's New

### 🆕 Complete Dialog & Text Editing System!

**Full-featured CLI tool for editing ALL game text with proper DTE compression!**

#### 🚀 Quick Start (PowerShell)

```powershell
# Easy task runner for Windows
.\ffmq-tasks.ps1 -Task help          # Show all available tasks
.\ffmq-tasks.ps1 -Task info          # Show project information
.\ffmq-tasks.ps1 -Task extract-text  # Extract all text from ROM
.\ffmq-tasks.ps1 -Task edit -Arg 5   # Edit dialog #5
.\ffmq-tasks.ps1 -Task build         # Build modified ROM
.\ffmq-tasks.ps1 -Task test          # Test in emulator
```

#### 🐧 Quick Start (Linux/Mac)

```bash
# Make-style task runner
make help           # Show all available tasks
make info           # Show project information
make extract-text   # Extract all text from ROM
make dialog-edit-5  # Edit dialog #5
make build          # Build modified ROM
make test           # Test in emulator
```

#### 📝 Advanced Usage

```bash
# Edit any dialog interactively
python tools/map-editor/dialog_cli.py edit 5

# Search dialogs
python tools/map-editor/dialog_cli.py search "Crystal"

# Export all dialogs to JSON
python tools/map-editor/dialog_cli.py export dialogs.json

# Import edited dialogs
python tools/map-editor/dialog_cli.py import dialogs.json

# Extract ALL game text (items, monsters, locations, dialogs)
python tools/extraction/extract_all_text.py roms/FFMQ.sfc

# Import edited text back to ROM
python tools/import/import_all_text.py data/text/text_data.json roms/FFMQ_modified.sfc
```

**Dialog System Features:**
- ✅ **116 dialogs** fully editable with DTE compression (57.9% space savings!)
- ✅ **Easy task runners:** PowerShell script (Windows) and Makefile (Linux/Mac)
- ✅ **15 CLI commands:** list, show, search, edit, export, import, stats, validate, backup, restore, replace, extract, compare, reformat, batch
- ✅ **77 control codes** mapped: [PARA], [PAGE], [WAIT], [CLEAR], [NAME], [ITEM], etc.
- ✅ **Complete text extraction:** Items, weapons, armor, accessories, spells, monsters, locations, dialogs
- ✅ **Auto-fix validation:** Removes double spaces, trims whitespace, normalizes control codes
- ✅ **Overflow detection:** Simulates dialog boxes, detects text overflow, suggests fixes
- ✅ **Compression optimizer:** Analyzes DTE usage, suggests improvements
- ✅ **Integration tests:** 5 comprehensive workflow tests
- ✅ **100% test pass rate** (where ROM available)

**Documentation:**
- [Workflow Guide](docs/WORKFLOW_GUIDE.md) - Complete workflow documentation (NEW!)
- [Quick Reference](tools/map-editor/QUICK_REFERENCE.md) - Fast 5-minute start
- [Dialog Commands Reference](docs/DIALOG_COMMANDS.md) - Complete control code catalog
- [Command Reference](tools/map-editor/COMMAND_REFERENCE.md) - All 15 CLI commands
- [Dialog System README](tools/map-editor/README.md) - Full technical guide

### 🔬 Advanced ROM Hacking Toolchain (NEW!)

**Complete analysis, compilation, and decompilation suite for event scripts!**

#### Analysis Tools (4 tools, 3,858 lines)

```bash
# Analyze event system patterns
python tools/analysis/event_system_analyzer.py --rom ffmq.sfc --table simple.tbl

# Auto-detect unknown command purposes
python tools/analysis/parameter_pattern_analyzer.py --input output/ --output docs/

# Validate character encoding tables
python tools/analysis/character_encoding_verifier.py --simple simple.tbl --rom ffmq.sfc
```

**Toolchain Features:**
- ✅ **Event System Analyzer** - Analyzes all 256 dialogs as event scripts (1,240 lines)
- ✅ **Parameter Pattern Analyzer** - Auto-suggests unknown command meanings (1,028 lines)
- ✅ **Character Encoding Verifier** - Validates .tbl files with round-trip tests (830 lines)
- ✅ **Enhanced Dialog Compiler** - Full 48-command support with validation (620 lines)
- ✅ **Event Script Decompiler** - ROM→human-readable conversion (760 lines)
- ✅ **All tools use TABS formatting** (not spaces)
- ✅ **Production-ready** with comprehensive error handling
- ✅ **Complete documentation** in ROM_HACKING_TOOLCHAIN_GUIDE.md

**Key Capabilities:**
- **48 event commands** fully supported (0x00-0x2F)
- **Parameter validation** with type checking and range validation
- **Control flow analysis** (subroutine calls, branches, loops)
- **Memory operation tracking** (quest flags, game state)
- **Statistical analysis** with hypothesis generation
- **Round-trip compilation** (text→ROM→text)
- **Comprehensive reporting** (JSON, CSV, Markdown)

**Example Workflow:**

```bash
# 1. Analyze existing ROM event scripts
python tools/analysis/event_system_analyzer.py \
	--rom ffmq.sfc --table simple.tbl --output analysis/

# 2. Auto-detect unknown command meanings
python tools/analysis/parameter_pattern_analyzer.py \
	--input analysis/ --output docs/hypotheses/

# 3. Decompile specific event script
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc --table simple.tbl \
	--offsets 0x8FA0,0x9000 --output decompiled.txt

# 4. Edit decompiled script in text editor
# (Modify decompiled.txt)

# 5. Compile modified script back to ROM format
python tools/rom_hacking/enhanced_dialog_compiler.py \
	--script modified.txt --table simple.tbl \
	--validate --output compiled.bin

# 6. Verify character encoding
python tools/analysis/character_encoding_verifier.py \
	--simple simple.tbl --rom modified_ffmq.sfc
```

**Documentation:**
- [ROM Hacking Toolchain Guide](docs/ROM_HACKING_TOOLCHAIN_GUIDE.md) - Complete workflow guide (NEW!)
- [Event System Architecture](docs/EVENT_SYSTEM_ARCHITECTURE.md) - System design documentation
- [Parameter Analysis Report](docs/PARAMETER_ANALYSIS_REPORT.md) - Command hypothesis generation
- [Tools Analysis README](tools/analysis/README.md) - Analysis tools reference
- [Tools ROM Hacking README](tools/rom_hacking/README.md) - Compilation/decompilation reference

### 🎮 Complete Battle Data Modding Pipeline!

**You can now visually edit enemies and build modified ROMs!**

```bash
# 1. Edit enemies visually
enemy_editor.bat

# 2. Build modified ROM
pwsh -File build.ps1

# 3. Test in emulator
mesen build/ffmq-rebuilt.sfc
```

**Enemy Editor Features:**
- ✅ Visual GUI editor for all 83 enemies
- ✅ Edit HP, Attack, Defense, Speed, Magic, and all stats
- ✅ Visual element resistance/weakness selection (16 elements)
- ✅ Search, filter, undo/redo support
- ✅ JSON-based workflow for batch modifications
- ✅ Automatic build integration (your edits appear in ROM!)
- ✅ Comprehensive test suite (all tests passing)
- ✅ GameFAQs data verification

**Documentation:**
- [Modding Quick Reference](docs/guides/MODDING_QUICK_REFERENCE.md) - Quick start guide
- [Enemy Editor Guide](docs/ENEMY_EDITOR_GUIDE.md) - Detailed GUI guide
- [Battle Data Pipeline](docs/BATTLE_DATA_PIPELINE.md) - Technical details
- [Build Integration Complete](docs/historical/BUILD_INTEGRATION_COMPLETE.md) - Build system docs

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

## Complete Tools Reference

### 🎨 Graphics Tools

**Extract and convert SNES graphics to/from PNG**

```bash
# Extract all graphics from ROM
python tools/extract_graphics_v2.py roms/FFMQ.sfc

# Convert individual graphics to PNG
python tools/convert_graphics.py to-png input.bin output.png --format 4bpp

# Convert PNG back to SNES format
python tools/convert_graphics.py to-snes input.png output.bin --format 4bpp
```

**Tools:**
- `tools/snes_graphics.py` - Core SNES tile/palette codec (450 lines)
- `tools/convert_graphics.py` - PNG conversion (440 lines)
- `tools/extract_graphics_v2.py` - ROM extraction (370 lines)

**Formats Supported:** 2bpp, 3bpp, 4bpp, 8bpp | **Compression:** None, RLE, LZ77

### 💬 Dialog & Text Tools

**Complete dialog editing system with DTE compression**

```bash
# Dialog CLI (15 commands)
cd tools/map-editor
python dialog_cli.py list                    # List all dialogs
python dialog_cli.py show 5                  # Show dialog #5
python dialog_cli.py search "Crystal"        # Search for text
python dialog_cli.py edit 5                  # Edit dialog interactively
python dialog_cli.py export dialogs.json     # Export to JSON
python dialog_cli.py import dialogs.json     # Import from JSON
python dialog_cli.py stats                   # Show statistics
python dialog_cli.py validate --fix          # Validate and auto-fix
python dialog_cli.py backup                  # Create backup
python dialog_cli.py restore backup_*.sfc    # Restore backup
python dialog_cli.py replace "old" "new"     # Batch replace
python dialog_cli.py compare rom1.sfc rom2.sfc  # Compare dialogs
python dialog_cli.py reformat --operations "trim,normalize"  # Format text
python dialog_cli.py batch commands.txt      # Batch operations

# Extract ALL game text (items, monsters, locations, dialogs)
cd tools/extraction
python extract_all_text.py roms/FFMQ.sfc --output-dir ../../data/text

# Import edited text back to ROM
cd tools/import
python import_all_text.py ../../data/text/text_data.json roms/FFMQ_modified.sfc

# Analysis tools
cd tools/map-editor
python compression_optimizer.py              # Analyze DTE compression
python text_overflow_detector.py             # Detect dialog overflow
```

**Dialog System Specs:**
- **116 dialogs** with full DTE compression (57.9% savings)
- **77 control codes:** [PARA], [PAGE], [WAIT], [CLEAR], [NAME], [ITEM], etc.
- **Dialog box:** 32 chars/line, 3 lines/page, 4 max pages
- **Proportional font** with character width simulation

**Tools:**
- `tools/map-editor/dialog_cli.py` - 15-command CLI (1,325 lines)
- `tools/map-editor/utils/dialog_text.py` - Text codec (698 lines)
- `tools/map-editor/utils/dialog_database.py` - Dialog storage (750 lines)
- `tools/extraction/extract_all_text.py` - Full text extraction (445 lines)
- `tools/import/import_all_text.py` - Text import (325 lines)
- `tools/map-editor/compression_optimizer.py` - DTE analysis (280 lines)
- `tools/map-editor/text_overflow_detector.py` - Overflow detection (360 lines)

**Documentation:**
- [Dialog Commands Reference](docs/DIALOG_COMMANDS.md) - Control code catalog
- [Command Reference](tools/map-editor/COMMAND_REFERENCE.md) - All CLI commands
- [Dialog System README](tools/map-editor/README.md) - Complete guide

### ⚔️ Battle Data Tools

**Visual enemy editor with JSON workflow**

```bash
# GUI enemy editor
enemy_editor.bat

# Or use Python directly
cd tools/map-editor
python enemy_editor.py

# Extract enemy data to JSON
python extract_enemy_data.py roms/FFMQ.sfc data/enemies.json

# Import edited enemy data
python import_enemy_data.py data/enemies.json roms/FFMQ_modified.sfc
```

**Enemy Editor Features:**
- Edit all 83 enemies visually
- HP, Attack, Defense, Speed, Magic, GP, EXP
- 16 element resistances/weaknesses
- Search, filter, undo/redo
- Automatic build integration

**Tools:**
- `tools/map-editor/enemy_editor.py` - Visual GUI editor
- `tools/map-editor/extract_enemy_data.py` - Enemy extraction
- `tools/map-editor/import_enemy_data.py` - Enemy import

**Documentation:**
- [Enemy Editor Guide](docs/ENEMY_EDITOR_GUIDE.md)
- [Battle Data Pipeline](docs/BATTLE_DATA_PIPELINE.md)

### 🔨 Development Tools

**Code formatting and utilities**

```powershell
# Format assembly files
.\tools\format_asm.ps1 -Path src\asm\bank_00.asm

# Convert Python files to tabs
python tools/dev/convert_to_tabs.py

# Track file changes
.\track.ps1

# Start automatic logging
.\start-tracking.ps1
```

**Tools:**
- `tools/format_asm.ps1` - ASM code formatter
- `tools/dev/convert_to_tabs.py` - Python tab converter
- `track.ps1` - File change tracker
- `log.ps1` - Automatic chat logger

### 📊 Analysis Tools

**ROM analysis and statistics**

```bash
# Text statistics
python tools/extraction/extract_all_text.py roms/FFMQ.sfc
# Creates text_statistics.txt with compression metrics

# Dialog statistics
cd tools/map-editor
python dialog_cli.py stats

# DTE compression analysis
python compression_optimizer.py

# Dialog overflow detection
python text_overflow_detector.py
```

**Output:**
- Character frequency analysis
- DTE compression ratios
- Control code usage
- Overflow warnings
- Optimization suggestions

### 🧪 Testing Tools

**Comprehensive test suites**

```bash
# Dialog system tests
cd tools/map-editor
python -m pytest test_import.py              # Import tests
python -m pytest test_integration.py         # Integration tests

# Enemy editor tests
python -m pytest tests/test_enemy_editor.py

# Run all tests
python -m pytest
```

**Test Coverage:**
- Unit tests for core modules
- Integration tests for workflows
- ROM validation tests
- Encoding/decoding tests

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

### Modifying Enemy Data (NEW! GUI Editor Available)
**Quick Start:**
```bash
# Windows
enemy_editor.bat

# Linux/Mac
./enemy_editor.sh
```

**Features:**
- ✨ Visual editing of all 83 enemies
- 📊 Edit HP, Attack, Defense, Speed, and all stats
- 🔥 Visual element resistance/weakness selection
- 💾 One-click save and export to ASM
- ✅ GameFAQs data verification built-in
- ⚡ Real-time preview with sliders

**See:** [Enemy Editor Guide](docs/ENEMY_EDITOR_GUIDE.md) for complete tutorial

**Alternative (Command Line):**
1. Extract enemy data: `python tools/extraction/extract_enemies.py`
2. Edit `data/extracted/enemies/enemies.json`
3. Convert to ASM: `python tools/conversion/convert_all.py`
4. Build ROM with modified data

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

📚 **[Complete Documentation Index](docs/INDEX.md)** - Master index for all project documentation!

🎯 **[Project Overview](docs/PROJECT_OVERVIEW.md)** ⭐ - Comprehensive project guide covering everything!

### Quick Links by Role

**New Users:**
1. [Project Overview](docs/PROJECT_OVERVIEW.md) ⭐ - Complete introduction
2. [Quick Start Guide](docs/guides/QUICK_START_GUIDE.md) - Get started fast
3. [Build Quick Start](docs/guides/BUILD_QUICK_START.md) - Build your first ROM
4. [FAQ](docs/guides/FAQ.md) - Common questions answered

**Modders:**
1. [Modding Quick Reference](docs/guides/MODDING_QUICK_REFERENCE.md) ⭐ - 3-step modding guide
2. [Complete Modding Tutorial](docs/MODDING_TUTORIAL.md) ⭐ - Beginner to advanced (2-4 hours)
3. [Enemy Editor Guide](docs/ENEMY_EDITOR_GUIDE.md) ✨ NEW! - Visual enemy editor (GUI)
4. [Battle Data Pipeline](docs/BATTLE_DATA_PIPELINE.md) - Data modification workflow
5. [Graphics Quick Start](docs/graphics-quickstart.md) - Graphics modding

**Developers:**
1. [Developer Onboarding](docs/DEVELOPER_ONBOARDING.md) ⭐ - 0 to productive in 60 minutes!
2. [Contributing](CONTRIBUTING.md) ⭐ - How to contribute
3. [Build Guide](docs/guides/BUILD_GUIDE.md) - Comprehensive build system
4. [Architecture](docs/ARCHITECTURE.md) - Project architecture
5. [Function Reference](docs/FUNCTION_REFERENCE.md) - Complete code reference (18K+ lines)

**Researchers:**
1. [Bank Classification](docs/technical/BANK_CLASSIFICATION.md) - ROM structure
2. [ROM Data Map](docs/ROM_DATA_MAP.md) - Complete ROM map
3. [Battle System](docs/BATTLE_SYSTEM.md) - Battle mechanics
4. [Technical Analysis](docs/technical/TECHNICAL_ANALYSIS_2025-11-06.md) - Latest analysis

### Documentation Categories

- **[Guides](docs/guides/)** - User and developer guides (BUILD_GUIDE, QUICK_START, FAQ, etc.)
- **[Technical](docs/technical/)** - ROM structure, data formats, system analysis
- **[Status](docs/status/)** - Progress reports and project status
- **[Project Management](docs/project-management/)** - TODO lists, roadmaps, issues
- **[DataCrystal](docs/datacrystal/)** - DataCrystal wiki integration
- **[Historical](docs/historical/)** - Session logs and completion reports

See **[docs/INDEX.md](docs/INDEX.md)** for the complete, organized documentation index.

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
