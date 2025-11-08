# Tools Directory# FFMQ Tools Directory



> **Complete tooling suite for Final Fantasy Mystic Quest ROM hacking, disassembly, modding, and research.**> **📖 Complete Tool Documentation:** See [TOOLS_REFERENCE.md](../docs/TOOLS_REFERENCE.md) for comprehensive documentation of all 130+ Python and PowerShell tools.



## 📁 Reorganized Directory StructureThis directory contains tools for ROM hacking, modding, and disassembly.



Tools are now organized into logical subdirectories by function for easier navigation and discovery:## Quick Links



```- **[Complete Tools Reference](../docs/TOOLS_REFERENCE.md)** - Full documentation of all tools

tools/- **[Enemy Editor Guide](../docs/ENEMY_EDITOR_GUIDE.md)** - Visual enemy editor tutorial

├── analysis/          - Project and code analysis- **[Battle Data Pipeline](../docs/BATTLE_DATA_PIPELINE.md)** - Battle data workflow

├── assets/            - Asset storage (palettes, fonts)- **[Graphics Quickstart](../docs/graphics-quickstart.md)** - Graphics tools guide

├── battle/            - Battle data, enemies, spells

├── build/             - ROM building and verification## Table of Contents

├── conversion/        - Data format conversion

├── data-extraction/   - Extract assets from ROM### Battle Data Modding Tools

├── disassembly/       - Disassembly and label management1. [Enemy Editor GUI](#enemy-editor-gui) - Visual enemy editor ⭐

├── examples/          - Example files and test data2. [Enemy Stats Viewer](#enemy-stats-viewer) - Quick command-line stats viewer

├── extraction/        - Specialized extraction (subdirectory)3. [ROM Comparison](#rom-comparison) - Compare ROM differences

├── formatting/        - Code formatting and standardization4. [Build & Compare](#build--compare) - Automated build workflow

├── github/            - GitHub integration and automation5. [Test Suite](#test-suite) - Master test runner

├── graphics/          - Graphics processing and conversion6. [Data Pipeline](#data-pipeline) - Extract, convert, integrate battle data

├── import/            - Import modified data to ROM

├── injection/         - Data injection utilities### Disassembly Tools

├── mods/              - Sample modification scripts7. [Address Scanner](#address-scanner) - Scan and catalog all raw memory addresses

├── rom-operations/    - Direct ROM manipulation8. [ROM Data Catalog](#rom-data-catalog) - Catalog all DATA8/DATA16/ADDR labels

├── testing/           - Test framework and validation9. [Label Application Tool](#label-application-tool) - Apply labels to assembly files

├── tracking/          - Progress tracking and logging

├── validation/        - Data validation---

└── visualization/     - Data visualization and charting

```## Battle Data Modding Tools



## 🚀 Quick Start by RoleComplete toolkit for editing enemy stats, attacks, and battle data in FFMQ.



### 🎮 **For Modders**### Enemy Editor GUI

```bash

# Edit enemy stats visually**File:** `enemy_editor_gui.py`  

python tools/battle/enemy_editor_gui.py**Launcher:** `enemy_editor.bat` (Windows) / `enemy_editor.sh` (Linux/Mac)  

**Documentation:** `docs/ENEMY_EDITOR_GUIDE.md`

# Extract sprite for editing

python tools/data-extraction/extract_graphics_v2.py --type sprite --id 42 --output sprite_42.png#### Purpose



# Edit sprite_42.png in your image editorVisual GUI for editing all 83 enemies in Final Fantasy Mystic Quest with real-time validation, undo/redo support, and built-in testing.



# Import modified sprite#### Features

python tools/import/import_graphics.py --input sprite_42.bin --id 42

✅ **Visual editing** - Browse all enemies with search and filtering  

# Build modified ROM✅ **Intuitive controls** - Sliders and spinboxes for all stats  

python tools/build/build_rom.py✅ **Element editor** - Visual selection for resistances/weaknesses  

```✅ **Undo/redo** - Full undo history (Ctrl+Z/Ctrl+Y)  

✅ **GameFAQs validation** - Verify accuracy against community data  

### 👨‍💻 **For Developers**✅ **Pipeline testing** - Test data extraction and conversion  

```bash✅ **Export options** - Save JSON or generate ASM directly

# Set up watch mode for development

.\tools\build\Build-Watch.ps1#### Quick Start



# Make changes to src/```bash

# Windows

# Tests run automatically, ROM rebuilds on saveenemy_editor.bat



# Manual test run# Linux/Mac

python tools/testing/run_all_tests.py./enemy_editor.sh



# Check build integrity# Or directly

python tools/build/verify_build_integration.pypython tools/enemy_editor_gui.py

``````



### 🔬 **For Researchers**#### Workflow

```bash

# Extract all game data1. **Browse** - Select enemy from list or search by name

python tools/data-extraction/extract_all_assets.py --output assets/2. **Edit** - Modify stats using sliders/spinboxes

3. **Save** - Click "Save Enemy" or press Ctrl+S

# Analyze spell system4. **Export** - Generate JSON (Ctrl+E) for ROM building

python tools/battle/analyze_spell_structure.py5. **Test** - Verify with built-in GameFAQs check



# Visualize enemy attack patterns---

python tools/graphics/visualize_enemy_attacks.py --output enemy_attacks.png

### Enemy Stats Viewer

# Document findings

python tools/tracking/update_chat_log.py --note "Discovered spell data format at $10C000"**File:** `view_enemy.py`

```

#### Purpose

## 📚 Comprehensive Documentation

Command-line tool for quickly viewing enemy stats without opening the GUI.

### Core Tool Categories

#### Quick Start

Each category has its own detailed README with usage examples:

```bash

#### ⚔️ **Battle Tools** - [battle/README.md](battle/README.md)# View specific enemy

Enemy data, spells, attacks, and battle mechanics.python tools/view_enemy.py Brownie

- **enemy_editor_gui.py** ⭐ - GUI enemy stat editor

- **view_enemy.py** - Command-line enemy viewer# View by ID

- **analyze_spell_structure.py** - Spell system researchpython tools/view_enemy.py 0

- **generate_attack_table.py** - Attack lookup tables

- **integrate_battle_data.py** - Import battle data to ROM# List all enemies

python tools/view_enemy.py --list

#### 🎨 **Graphics Tools** - [graphics/README.md](graphics/README.md)

SNES graphics, palettes, sprites, and visual data.# Search for enemies

- **snes_graphics.py** ⭐ - Core SNES graphics library (2bpp/4bpp/8bpp)python tools/view_enemy.py --search slime

- **convert_graphics.py** ⭐ - PNG ↔ CHR conversion

- **palette_manager.py** - Palette editing (BGR555 ↔ RGB)# Brief output (basic stats only)

- **visualize_elements.py** - Element interaction chartspython tools/view_enemy.py Brownie --brief

- **inventory_graphics.py** - Generate graphics catalog```



#### 🏗️ **Build Tools** - [build/README.md](build/README.md)#### Output Example

ROM assembly, verification, and comparison.

- **build_rom.py** ⭐ - Main ROM build script```

- **verify_build_integration.py** ⭐ - Comprehensive verificationEnemy #000: Brownie

- **compare_roms.py** - Byte-by-byte ROM comparisonBASIC STATS:

- **Build-System.ps1** - PowerShell build orchestrator  HP:              50

- **Build-Watch.ps1** - Watch mode for live rebuilds  Attack:           3

  Defense:          1

#### 📦 **Data Extraction** - [data-extraction/README.md](data-extraction/README.md)  Speed:            3

Extract graphics, text, music, maps, and data.  Magic:            1

- **extract_all_assets.py** ⭐ - One-command full extractionLEVEL & REWARDS:

- **extract_graphics_v2.py** ⭐ - Advanced graphics extractor  Level:            1

- **extract_text_enhanced.py** - Text and dialogue extraction  XP Multiplier:   22

- **extract_maps_enhanced.py** - Map data extraction  GP Multiplier:    1

- **extract_music.py** - SPC music extractionRESISTANCES: None

WEAKNESSES: None

#### 📊 **Analysis Tools** - [analysis/README.md](analysis/README.md)```

Project metrics, documentation coverage, progress tracking.

- **project_status.py** - Comprehensive project status report---

- **analyze_doc_coverage.py** - Documentation coverage analysis

- **analyze_project_priorities.py** - Priority-ordered task list### ROM Comparison

- **code_label_analyzer.py** - Label usage and conflicts

**File:** `compare_roms.py`

#### 🧪 **Testing Tools** - [testing/README.md](testing/README.md)

Automated testing, ROM validation, CI/CD.#### Purpose

- **run_all_tests.py** ⭐ - Full test suite (142 tests)

- **rom_tester.py** - Automated ROM functionality testingCompare two SNES ROM files byte-by-byte with region identification and detailed difference reporting.

- **test_pipeline.py** - Pipeline integration tests

- **verify_gamefaqs_data.py** - Validate against GameFAQs#### Features



#### 📝 **Formatting Tools** - [formatting/README.md](formatting/README.md)✅ **Byte comparison** - Find all differences between ROMs  

Assembly code formatting and standardization.✅ **Region mapping** - Identify changed sections (Enemy Stats, Attack Data, etc.)  

- **format_asm.ps1** ⭐ - Comprehensive assembly formatter✅ **Hex dumps** - View exact byte differences  

- **normalize_case.py** - Instruction/register case✅ **Statistics** - Count and percentage of changes  

- **normalize_indentation.py** - Indentation standardization✅ **Grouping** - Group consecutive byte differences

- **fix_duplicate_labels.py** - Resolve label conflicts

#### Quick Start

#### 🔍 **Disassembly Tools** - [disassembly/README.md](disassembly/README.md)

ROM disassembly, label management, reference imports.```bash

- **mass_disassemble.py** - Batch disassembly# Basic comparison

- **Aggressive-Disassemble.ps1** - Heuristic disassemblypython tools/compare_roms.py original.sfc modified.sfc

- **convert_diztinguish.py** - Import Diztinguish projects

- **apply_labels.ps1** - Apply label definitions# Show hex dumps of differences

python tools/compare_roms.py rom1.sfc rom2.sfc --verbose

#### 💾 **ROM Operations** - [rom-operations/README.md](rom-operations/README.md)

Direct ROM manipulation, compression, data structures.# Group by known regions

- **rom_compare.py** - Detailed ROM comparisonpython tools/compare_roms.py rom1.sfc rom2.sfc --regions

- **rom_integrity.py** - Checksum validation and fixing

- **ffmq_compression.py** ⭐ - FFMQ compression/decompression# Full analysis

- **ffmq_data_structures.py** ⭐ - Data format definitionspython tools/compare_roms.py rom1.sfc rom2.sfc --verbose --regions

- **mesen_integration.py** - Emulator integration```



#### 📈 **Tracking Tools** - [tracking/README.md](tracking/README.md)#### Known Regions

Progress tracking, session logging, metrics.

- **update_chat_log.py** ⭐ - Session change logging- Enemy Stats Data (`$014275-$01469F`)

- **auto_tracker.py** - Automated progress tracking- Enemy Levels Data (`$01417C-$0141FC`)

- **disassembly_tracker.py** - Disassembly completion tracking- Attack Data (`$014678-$014776`)

- **track_extraction.py** - Asset extraction progress- Text Data

- Graphics Data

#### 🐙 **GitHub Integration** - [github/README.md](github/README.md)

GitHub automation, issue management, project boards.---

- **create_github_issues.ps1** - Bulk issue creation

- **create_github_sub_issues.ps1** - Epic → sub-issue breakdown### Build & Compare

- **setup_project_board.ps1** - Project board automation

- **link_child_issues_to_parents.ps1** - Issue hierarchy**File:** `build_and_compare.py`



## 📖 Complete Tool References#### Purpose



### Detailed DocumentationAutomated workflow tool that builds a modified ROM and compares it with the previous build to show what changed.

- **[TOOLS_REFERENCE.md](../docs/TOOLS_REFERENCE.md)** - Complete Python tools documentation

  - 130+ Python scripts documented#### Workflow

  - Organized by category

  - Usage examples for each tool1. **Backup** - Creates `.backup` of current ROM

  - Common workflows2. **Convert** - Runs JSON → ASM conversion

3. **Build** - Executes build script

- **[POWERSHELL_REFERENCE.md](../docs/POWERSHELL_REFERENCE.md)** - Complete PowerShell scripts documentation4. **Compare** - Shows differences vs backup

  - 30+ PowerShell scripts documented5. **Cleanup** - Optionally removes backup

  - Build automation

  - Formatting pipelines#### Quick Start

  - GitHub integration

```bash

## 🎯 Common Tools by Task# Build and compare

python tools/build_and_compare.py

### Editing Game Data

| Task | Tool | Location |# Show detailed differences

|------|------|----------|python tools/build_and_compare.py --verbose

| Edit enemies (GUI) | `enemy_editor_gui.py` | `tools/battle/` |

| View enemy stats | `view_enemy.py` | `tools/battle/` |# Keep backup file

| Edit spells | `analyze_spell_structure.py` | `tools/battle/` |python tools/build_and_compare.py --keep-temp

| Import data | `import_data.py` | `tools/import/` |```



### Working with Graphics#### Output Example

| Task | Tool | Location |

|------|------|----------|```

| Extract sprites | `extract_graphics_v2.py` | `tools/data-extraction/` |[INFO] Creating backup: build/ffmq-rebuilt.sfc.backup

| Convert PNG→CHR | `convert_graphics.py` | `tools/graphics/` |[INFO] Converting battle data...

| Edit palettes | `palette_manager.py` | `tools/graphics/` |[OK] Conversion complete

| Import graphics | `import_graphics.py` | `tools/import/` |[INFO] Building ROM...

[OK] Build complete

### Building and Testing[INFO] Comparing ROMs...

| Task | Tool | Location |[OK] Found 127 bytes different (0.02%)

|------|------|----------|[INFO] Differences by region:

| Build ROM | `build_rom.py` | `tools/build/` |  - Enemy Stats: 127 bytes changed

| Verify build | `verify_build_integration.py` | `tools/build/` |```

| Compare ROMs | `compare_roms.py` | `tools/build/` |

| Run tests | `run_all_tests.py` | `tools/testing/` |---

| Watch mode | `Build-Watch.ps1` | `tools/build/` |

### Test Suite

### Documentation and Analysis

| Task | Tool | Location |**File:** `run_all_tests.py`

|------|------|----------|

| Project status | `project_status.py` | `tools/analysis/` |#### Purpose

| Doc coverage | `analyze_doc_coverage.py` | `tools/analysis/` |

| Log changes | `update_chat_log.py` | `tools/tracking/` |Master test suite runner for validating the complete battle data pipeline.

| Track progress | `auto_tracker.py` | `tools/tracking/` |

#### Test Categories

## 💡 Complete Workflows

**Pipeline Tests** (`--category pipeline`)

### 🎮 Complete Modding Workflow- Enemy data extraction

```bash- JSON modification

# 1. Extract original data- JSON → ASM conversion

python tools/data-extraction/extract_all_assets.py --output assets/- Complete round-trip workflow



# 2. Edit data (choose one method)**GameFAQs Verification** (`--category gamefaqs`)

# Method A: GUI editor- Community data validation

python tools/battle/enemy_editor_gui.py- HP value accuracy

- Cross-reference with DrProctor's guide

# Method B: Extract → Edit → Import

python tools/battle/view_enemy.py --export enemies.json**Build Integration** (`--category build`)

# Edit enemies.json in text editor- ROM data verification

python tools/battle/integrate_battle_data.py --input enemies.json- Address mapping validation

- All 83 enemies present in ROM

# 3. Rebuild ROM

python tools/build/build_rom.py#### Quick Start



# 4. Verify changes```bash

python tools/build/compare_roms.py roms/original.smc build/ffmq.smc# Run all tests

python tools/run_all_tests.py

# 5. Test in emulator

python tools/rom-operations/mesen_integration.py --rom build/ffmq.smc# Run specific category

python tools/run_all_tests.py --category pipeline

# 6. Create distribution patchpython tools/run_all_tests.py --category gamefaqs

python tools/build/create_patch.py --original roms/original.smc --modified build/ffmq.smc --output my_mod.ipspython tools/run_all_tests.py --category build

```

# Verbose output

### 👨‍💻 Development Workflowpython tools/run_all_tests.py --verbose

```powershell```

# 1. Start watch mode (PowerShell)

.\tools\build\Build-Watch.ps1#### Output Example



# This automatically:```

# - Watches for file changesRunning test category: all

# - Rebuilds ROM on save✓ Pipeline End-to-End Tests PASSED (REQUIRED)

# - Runs validation✓ GameFAQs Data Verification PASSED (OPTIONAL)

# - Displays errors✓ Build Integration Verification PASSED (REQUIRED)



# 2. Make changes to src/*.asm filesAll 3 test suites passing!

# (Auto-rebuilds happen in background)```



# 3. Manual test run (separate terminal)---

python tools/testing/run_all_tests.py

### Data Pipeline

# 4. Check specific test

python tools/testing/run_tests.py tests/unit/test_snes_graphics.pyComplete workflow for extracting, converting, and integrating battle data.



# 5. Verify build integrity#### Extraction Tools

python tools/build/verify_build_integration.py

**Location:** `tools/extraction/`

# 6. Log session work

python tools/tracking/update_chat_log.py --change "Documented 42 Bank $03 functions"```bash

# Extract enemy stats

# 7. Commit changespython tools/extraction/extract_enemies.py roms/your-rom.sfc

git add src/

git commit -m "Document Bank $03 functions"# Extract attack data

git pushpython tools/extraction/extract_attacks.py roms/your-rom.sfc

```

# Extract enemy-attack links

### 🔬 Research Workflowpython tools/extraction/extract_enemy_attack_links.py roms/your-rom.sfc

```bash```

# 1. Extract data of interest

python tools/data-extraction/extract_bank06_data.py --output bank06/**Output:** JSON files in `data/extracted/`



# 2. Analyze structure#### Conversion Tools

python tools/battle/analyze_spell_structure.py

python tools/battle/analyze_spell_flags.py**Location:** `tools/conversion/`



# 3. Test hypotheses```bash

python tools/battle/test_spell_learning_hypothesis.py# Convert all data (recommended)

python tools/conversion/convert_all.py

# 4. Visualize findings

python tools/graphics/visualize_spell_effectiveness.py --output spell_analysis.png# Or convert individually

python tools/conversion/convert_enemies.py

# 5. Generate research reportpython tools/conversion/convert_attacks.py

python tools/battle/spell_research_report.py --output spell_report.mdpython tools/conversion/convert_enemy_attack_links.py

```

# 6. Document discoveries

python tools/tracking/update_chat_log.py --note "Spell learning controlled by byte at offset +$05"**Output:** Assembly files in `data/converted/`



# 7. Update technical documentation#### Verification Tools

# Edit docs/technical/SPELL_DATA_FORMAT.md

```bash

# 8. Validate findings# Test complete pipeline

python tools/battle/verify_spell_data.pypython tools/test_pipeline.py

```

# Verify GameFAQs accuracy

### 🎨 Graphics Modding Workflowpython tools/verify_gamefaqs_data.py

```bash

# 1. Extract sprite and palette# Verify ROM integration

python tools/data-extraction/extract_graphics_v2.py --type sprite --id 42 --output sprite_42.pngpython tools/verify_build_integration.py

python tools/extraction/extract_enemy_palettes.py --id 42 --output palette_42.pal```



# 2. Edit sprite in image editor---

# - Open sprite_42.png in Aseprite/GraphicsGale

# - Maintain indexed color mode## Complete Modding Workflow

# - Keep palette intact

# - Export as PNG-8### Quick Start (3 Steps)



# 3. Convert to SNES format```bash

python tools/graphics/convert_graphics.py --input sprite_42_edited.png --output sprite_42.bin --format 4bpp# 1. Edit enemies

enemy_editor.bat

# 4. Import to ROM

python tools/import/import_graphics.py --type sprite --id 42 --input sprite_42.bin# 2. Build ROM

pwsh -File build.ps1

# 5. Build and test

python tools/build/build_rom.py# 3. Test in emulator

python tools/rom-operations/mesen_integration.py --rom build/ffmq.smcmesen build/ffmq-rebuilt.sfc

```

# 6. If colors wrong, edit palette

python tools/graphics/palette_manager.py --edit --input palette_42.pal### Development Workflow

python tools/graphics/palette_manager.py --apply --palette palette_42.pal --input sprite_42_edited.png

```bash

# Repeat steps 3-5# 1. Extract data from ROM

```python tools/extraction/extract_enemies.py roms/ffmq.sfc



## 📦 Installation and Dependencies# 2. Modify JSON

# (edit data/extracted/enemies/enemies.json)

### Python Requirements

```bash# 3. Convert to ASM

# Install all dependenciespython tools/conversion/convert_all.py

pip install -r requirements.txt

# 4. Test pipeline

# Core dependencies:python tools/test_pipeline.py

# - Python 3.7+

# - Pillow (graphics)# 5. Build and compare

# - numpy (analysis)python tools/build_and_compare.py --verbose

# - matplotlib (visualization)

# - pytest (testing)# 6. Run all tests

```python tools/run_all_tests.py

```

### PowerShell Requirements

```powershell### Tool Quick Reference

# PowerShell 5.1+

# For GitHub integration:| Tool | Command | Purpose |

Install-Module -Name PowerShellForGitHub|------|---------|---------|

```| Enemy Editor | `enemy_editor.bat` | Visual enemy editing |

| Stats Viewer | `python tools/view_enemy.py Brownie` | Quick stats lookup |

### External Tools| Test Suite | `python tools/run_all_tests.py` | Run all tests |

- **ASAR** - SNES assembler ([download](https://github.com/RPGHacker/asar))| Build & Compare | `python tools/build_and_compare.py` | Automated build workflow |

- **Mesen-S** - Emulator for testing (optional) ([download](https://www.mesen.ca))| ROM Compare | `python tools/compare_roms.py rom1.sfc rom2.sfc` | Compare ROMs |

- **Diztinguish** - Disassembly tool (optional) ([download](https://github.com/IsoFrieze/DiztinGUIsh))| Convert All | `python tools/conversion/convert_all.py` | JSON → ASM |



## 🔗 Related Documentation---



### Getting Started## Disassembly Tools

- **[PROJECT_OVERVIEW.md](../docs/PROJECT_OVERVIEW.md)** - Project overview and architecture

- **[DEVELOPER_ONBOARDING.md](../docs/DEVELOPER_ONBOARDING.md)** - Get productive in 60 minutesTools for analyzing and labeling the FFMQ disassembly.

- **[MODDING_TUTORIAL.md](../docs/MODDING_TUTORIAL.md)** - Modding tutorial (beginner → advanced)

- **[BUILD_GUIDE.md](../docs/guides/BUILD_GUIDE.md)** - Building ROM from source---



### Technical Documentation## Address Scanner

- **[FUNCTION_REFERENCE.md](../docs/technical/FUNCTION_REFERENCE.md)** - 2,486 documented functions

- **[ROM_MAP.md](../docs/technical/ROM_MAP.md)** - Complete ROM memory map**File:** `scan_addresses.ps1`  

- **[DATA_FORMATS.md](../docs/technical/DATA_FORMATS.md)** - Data structure specifications**Issue:** #23 - Memory Labels: Address Inventory and Analysis

- **[GRAPHICS_FORMAT.md](../docs/technical/GRAPHICS_FORMAT.md)** - SNES graphics formats

### Purpose

### Complete Index

- **[INDEX.md](../docs/INDEX.md)** - Master documentation indexScans all assembly files in the project to identify raw memory addresses, categorize them by type (WRAM, Hardware, ROM), count occurrences, and generate comprehensive reports for labeling prioritization.



## 🗂️ Tool Organization Rationale### Features



### Why Subdirectories?✅ **Comprehensive scanning** - Analyzes all ASM files recursively  

✅ **Smart categorization** - Identifies WRAM, PPU, Hardware, and ROM addresses  

**Before reorganization:**✅ **Usage tracking** - Counts occurrences of each unique address  

- 130+ scripts in flat `tools/` directory✅ **Priority assignment** - Ranks addresses by usage frequency and type  

- Difficult to find relevant tools✅ **Label suggestions** - Generates suggested label names based on address type  

- No clear categorization✅ **CSV reports** - Outputs detailed analysis in CSV format  

- Hard to discover related tools

### Quick Start

**After reorganization:**

- Logical grouping by function```powershell

- Each category has comprehensive README# Basic scan with default settings

- Related tools co-located.\scan_addresses.ps1

- Easy discovery and navigation

- Consistent structure# Scan with verbose output

.\scan_addresses.ps1 -VerboseOutput

### Subdirectory Design Principles

# Scan custom source path

1. **Functional grouping** - Tools grouped by what they do.\scan_addresses.ps1 -SourcePath "C:\myproject\src"

2. **Clear naming** - Directory names describe purpose

3. **Comprehensive docs** - Each subdirectory has detailed README# Custom output location

4. **Consistent structure** - All READMEs follow same format.\scan_addresses.ps1 -OutputPath "C:\myproject\analysis\addresses.csv"

5. **Cross-referencing** - Tools link to related categories```



## 🤝 Contributing New Tools### Output Format



### Adding a New ToolThe tool generates `reports/address_usage_report.csv` with the following columns:



1. **Determine category** - Which subdirectory does it belong in?- **Address** - The memory address (e.g., `$0000`, `$2116`)

2. **Follow naming convention** - Use descriptive, consistent names- **Type** - Category: WRAM, PPU, Hardware, ROM, Other

3. **Add documentation** - Comprehensive docstrings and comments- **Category** - Detailed category (e.g., "Zero Page", "PPU Registers")

4. **Update README** - Add to appropriate subdirectory README.md- **Occurrences** - Number of times the address appears in code

5. **Add to references** - Update TOOLS_REFERENCE.md or POWERSHELL_REFERENCE.md- **Priority** - Labeling priority: Critical, High, Medium, Low

6. **Create tests** - Add tests to `tools/testing/`- **Suggested_Label** - Auto-generated label suggestion

7. **Document workflows** - Add usage examples- **Example_Contexts** - Sample usage contexts from source files



### Naming Conventions### Priority Levels



**Python scripts:****WRAM Addresses:**

- `verb_noun.py` - Action-based naming- **Critical**: 50+ occurrences

- Examples: `extract_graphics.py`, `build_rom.py`, `analyze_spell_structure.py`- **High**: 20-49 occurrences

- **Medium**: 10-19 occurrences

**PowerShell scripts:**- **Low**: <10 occurrences

- `Verb-Noun.ps1` - PowerShell standard

- Examples: `Build-System.ps1`, `Format-Asm.ps1`**Hardware/PPU Addresses:**

- **High**: 10+ occurrences

**GUI tools:**- **Medium**: 5-9 occurrences

- `noun_editor_gui.py`- **Low**: <5 occurrences

- Examples: `enemy_editor_gui.py`

**ROM Addresses:**

### Documentation Standards- **High**: 100+ occurrences

- **Medium**: 50-99 occurrences

Each tool should have:- **Low**: <50 occurrences

- **Docstring** - Purpose and usage

- **Parameters** - All arguments documented### Usage Example

- **Examples** - Usage examples

- **Dependencies** - Required packages```powershell

- **See Also** - Related toolsPS> .\scan_addresses.ps1



## 🆘 Getting Help=== FFMQ Address Scanner ===

Scanning for raw memory addresses in assembly files

### Tool-Specific Help

```bash==> Scanning ASM files in: C:\ffmq-info\src

# Most Python tools support --helpFound 68 ASM files

python tools/battle/enemy_editor_gui.py --help✓ Scanned 68 files

python tools/build/build_rom.py --helpFound 192 unique addresses

==> Generating report: C:\ffmq-info\reports\address_usage_report.csv

# PowerShell scripts✓ Report generated successfully

Get-Help .\tools\build\Build-System.ps1

```=== Summary Statistics ===

Total unique addresses: 192

### Documentation  Hardware: 14

1. Start with subdirectory README (e.g., `tools/battle/README.md`)  PPU: 12

2. Check complete tool reference ([TOOLS_REFERENCE.md](../docs/TOOLS_REFERENCE.md))  ROM: 36

3. See project overview ([PROJECT_OVERVIEW.md](../docs/PROJECT_OVERVIEW.md))  WRAM: 123

4. Browse documentation index ([INDEX.md](../docs/INDEX.md))

By Priority:

### Support Channels  Critical: 1

- **Issues**: [GitHub Issues](https://github.com/TheAnsarya/ffmq-info/issues)  High: 7

- **FAQ**: [docs/guides/FAQ.md](../docs/guides/FAQ.md)  Medium: 16

- **Discussions**: GitHub Discussions  Low: 168



## 📊 Tool StatisticsTop 10 Most-Used Addresses:

  $0000 (WRAM): 60 occurrences - var_0000

- **Total Python Tools**: 130+  $420b (Hardware): 26 occurrences - MDMAEN

- **Total PowerShell Scripts**: 30+  $2116 (PPU): 20 occurrences - VMADDL

- **Tool Categories**: 17  ...

- **Lines of Documentation**: 15,000+

- **Test Coverage**: 65%✓ Complete! Report saved to: reports\address_usage_report.csv

```

## 🎓 Learning Path

### Parameters

### Beginner → Intermediate → Advanced

| Parameter | Type | Default | Description |

**Week 1: Basics**|-----------|------|---------|-------------|

1. Use `enemy_editor_gui.py` to modify enemies| `SourcePath` | string | `../src` | Directory containing ASM files to scan |

2. Extract graphics with `extract_graphics_v2.py`| `OutputPath` | string | `../reports/address_usage_report.csv` | Output CSV file path |

3. Build ROM with `build_rom.py`| `VerboseOutput` | switch | false | Display detailed progress information |

4. Test with `mesen_integration.py`

### Known Hardware Registers

**Week 2: Intermediate**

1. Learn extraction pipelineThe scanner automatically recognizes standard SNES hardware registers and suggests their official names:

2. Understand data formats

3. Use build verification- **PPU Registers** (`$2100-$21ff`): INIDISP, BGMODE, VMAIN, VMADDL, CGADD, etc.

4. Create simple mods- **CPU Registers** (`$4200-$43ff`): NMITIMEN, MDMAEN, HDMAEN, etc.

- **Controller Ports** (`$4016-$4017`): JOYSER0, JOYSER1

**Week 3: Advanced**

1. Disassemble ROM sections### Integration with Label Application

2. Analyze unknown data

3. Create new toolsThe output CSV is compatible with the Label Application Tool (`apply_labels.ps1`):

4. Contribute to project

```powershell

## 📄 License# 1. Scan addresses

.\scan_addresses.ps1

See [LICENSE](../LICENSE) for project license.

# 2. Edit the CSV to refine labels (optional)

## 🗺️ Navigation# Edit reports/address_usage_report.csv



- [← Back to Project Root](../)# 3. Apply labels using the CSV

- [📚 Documentation Index](../docs/INDEX.md).\apply_labels.ps1 -InputFile ..\reports\address_usage_report.csv -SourceFiles "..\src\asm\*.asm"

- [🎮 Modding Tutorial](../docs/MODDING_TUTORIAL.md)```

- [👨‍💻 Developer Onboarding](../docs/DEVELOPER_ONBOARDING.md)

- [📊 Project Status](../STATUS.md)---



---## ROM Data Catalog



**Last Updated**: November 7, 2025  **File:** `catalog_rom_data.ps1`  

**Tools Version**: 2.0 (Reorganized Structure)  **Issue:** #25 - Memory Labels: ROM Data Map Documentation

**Maintained By**: FFMQ Disassembly Project

### Purpose

Scans all documented ASM files to catalog DATA8/DATA16/ADDR labels, extracting table information, descriptions, and generating comprehensive reports organized by bank.

### Features

✅ **Complete cataloging** - Finds all DATA8_/DATA16_/ADDR_ labels  
✅ **Bank organization** - Groups tables by ROM bank  
✅ **Description extraction** - Pulls comments and descriptions from source  
✅ **Statistics generation** - Provides bank and type breakdowns  
✅ **CSV export** - Outputs structured catalog for analysis  

### Quick Start

```powershell
# Run the catalog scan
.\catalog_rom_data.ps1

# With custom paths
.\catalog_rom_data.ps1 -AsmPath "..\src\asm" -OutputPath "..\reports\catalog.csv"
```

### Output

Generates `reports/rom_data_catalog.csv` with complete ROM data table inventory:

- **Bank** - ROM bank number (00-0F)
- **Address** - Full 6-digit address
- **Label** - DATA8_/DATA16_/ADDR_ label name
- **Type** - DATA8, DATA16, or ADDR
- **DataType** - Data directive type (byte, word, long)
- **EstimatedSize** - Approximate table size in bytes
- **Description** - Extracted comment/description
- **File** - Source filename

### Usage Example

```powershell
PS> .\catalog_rom_data.ps1

🔍 Cataloging ROM Data Tables...
  Scanning bank_00_documented.asm...
  Scanning bank_01_documented.asm...
  ...
  Scanning bank_0D_documented.asm...

✅ Found 296 data tables
📝 Catalog saved to: reports\rom_data_catalog.csv

📊 Statistics by Bank:
  Bank $00 : 23 tables
  Bank $01 : 43 tables
  Bank $02 : 64 tables
  Bank $07 : 77 tables
  ...

📊 Statistics by Type:
  DATA8 : 295 tables
  DATA16 : 1 tables
```

### Statistics

Current catalog includes:
- **Total Tables:** 296 (295 DATA8, 1 DATA16)
- **Largest Bank:** Bank $07 with 77 tables (character/enemy data)
- **Complete Documentation:** `docs/ROM_DATA_MAP.md`

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `AsmPath` | string | `../src/asm` | Directory containing ASM files |
| `OutputPath` | string | `../reports/rom_data_catalog.csv` | Output CSV file path |

### Integration

Works with ROM_DATA_MAP.md documentation:

```powershell
# 1. Catalog all ROM data tables
.\catalog_rom_data.ps1

# 2. Review the catalog
Import-Csv ..\reports\rom_data_catalog.csv | Where-Object { $_.Bank -eq "07" } | Format-Table

# 3. Documentation is auto-updated in docs/ROM_DATA_MAP.md
```

---

## Label Application Tool

**File:** `apply_labels.ps1`  
**Issue:** #27 - Memory Labels: Label Replacement Tool Development

### Purpose

Automates the process of replacing memory addresses with descriptive labels in assembly source files. Ensures consistency, reduces errors, and speeds up the labeling process.

### Features

✅ **Multiple input formats** - Supports CSV and JSON  
✅ **Addressing mode detection** - Handles direct, absolute, long, and indexed modes  
✅ **Dry-run mode** - Preview changes before applying  
✅ **ROM verification** - Ensures byte-perfect match after replacement  
✅ **Automatic backups** - Saves original files before modification  
✅ **Detailed reporting** - Shows all replacements and summary statistics  

### Quick Start

```powershell
# Dry run to preview changes
.\apply_labels.ps1 -InputFile example_labels.csv -SourceFiles "src/asm/bank_00.asm" -DryRun

# Apply labels to a single file
.\apply_labels.ps1 -InputFile example_labels.csv -SourceFiles "src/asm/bank_00.asm"

# Apply labels to multiple files with verification
.\apply_labels.ps1 -InputFile example_labels.json -SourceFiles "src/asm/*.asm" -Verify

# Verbose output
.\apply_labels.ps1 -InputFile example_labels.csv -SourceFiles "src/asm/bank_00.asm" -Verbose
```

### Input File Formats

#### CSV Format

```csv
Address,Label,Type,Comment
$40,player_x_pos_lo,RAM,Player X position (low byte)
$41,player_x_pos_hi,RAM,Player X position (high byte)
$7e0040,player_x_pos,RAM,Player X position (word)
```

**Columns:**
- `Address` - Memory address (with or without $ prefix)
- `Label` - Label name (without ! prefix)
- `Type` - Type of data (RAM, ROM, etc.)
- `Comment` - Description

#### JSON Format

```json
{
  "metadata": {
	"project": "FFMQ Disassembly",
	"version": "1.0"
  },
  "mappings": [
	{
	  "address": "$40",
	  "label": "player_x_pos_lo",
	  "type": "RAM",
	  "comment": "Player X position (low byte)"
	}
  ]
}
```

### Addressing Modes Supported

The tool automatically detects and handles different addressing modes:

#### Direct Page ($00-$ff)
```assembly
; Before
LDA $40
STA $41,X

; After  
LDA !player_x_pos_lo
STA !player_x_pos_hi,X
```

#### Absolute ($0000-$ffff)
```assembly
; Before
LDA $7e40
INC $7e41,X

; After
LDA !player_x_pos
INC !player_y_pos,X
```

#### Long ($000000-$ffffff)
```assembly
; Before
LDA $7e0040
STA $7e0042,X

; After
LDA !player_x_pos
STA !player_y_pos,X
```

### Supported Instructions

The tool recognizes labels in the following 65816 instructions:

**Load/Store:**  
`LDA`, `LDX`, `LDY`, `STA`, `STX`, `STY`, `STZ`

**Arithmetic:**  
`ADC`, `SBC`, `INC`, `DEC`

**Logic:**  
`AND`, `ORA`, `EOR`, `BIT`

**Compare:**  
`CMP`, `CPX`, `CPY`

**Shift/Rotate:**  
`ASL`, `LSR`, `ROL`, `ROR`

**Test/Set/Reset:**  
`TSB`, `TRB`

**Jump/Call:**  
`JMP`, `JSR`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `InputFile` | String | Yes | Path to CSV or JSON label mappings file |
| `SourceFiles` | String[] | Yes | Assembly files to process (supports wildcards) |
| `DryRun` | Switch | No | Show changes without modifying files |
| `Verify` | Switch | No | Build ROM and verify byte-perfect match |
| `BackupDir` | String | No | Backup directory (default: `backups/`) |
| `OriginalROM` | String | No | Original ROM for verification (default: `roms/ffmq-original.sfc`) |
| `Verbose` | Switch | No | Show detailed replacement output |

### Examples

#### Example 1: Dry Run

```powershell
.\apply_labels.ps1 `
	-InputFile example_labels.csv `
	-SourceFiles "src/asm/bank_00.asm" `
	-DryRun
```

**Output:**
```
============================================================
  FFMQ LABEL APPLICATION TOOL
============================================================

ℹ Input File: example_labels.csv
ℹ Mode: DRY RUN (no changes)
✓ Loaded 38 label mappings

ℹ Processing: src/asm/bank_00.asm
✓ 15 replacements in bank_00.asm
⚠ DRY RUN - No changes written to file
ℹ Example changes:
  - LDA $40
  + LDA !player_x_pos_lo
  - STA $41
  + STA !player_x_pos_hi

============================================================
  SUMMARY
============================================================
ℹ Total replacements: 15
ℹ Files modified: 0 (DRY RUN)
```

#### Example 2: Apply with Verification

```powershell
.\apply_labels.ps1 `
	-InputFile example_labels.json `
	-SourceFiles "src/asm/bank_00.asm","src/asm/bank_01.asm" `
	-Verify
```

**Output:**
```
============================================================
  FFMQ LABEL APPLICATION TOOL
============================================================

ℹ Input File: example_labels.json
ℹ Mode: APPLY CHANGES
ℹ Verification: ENABLED
✓ Loaded 38 label mappings

ℹ Processing: src/asm/bank_00.asm
✓ 15 replacements in bank_00.asm
ℹ Backup created: backups/bank_00.asm.bak
✓ File updated successfully

ℹ Processing: src/asm/bank_01.asm
✓ 8 replacements in bank_01.asm
ℹ Backup created: backups/bank_01.asm.bak
✓ File updated successfully

============================================================
  ROM VERIFICATION
============================================================

ℹ Asar version: 1.81
ℹ Calculating original ROM checksum...
  Original MD5: A1B2C3D4E5F6...
ℹ Building ROM from modified source...
✓ Build completed successfully
ℹ Calculating modified ROM checksum...
  Modified MD5: A1B2C3D4E5F6...
✓ ROM VERIFICATION PASSED - Byte-perfect match!

============================================================
  SUMMARY
============================================================
ℹ Total replacements: 23
ℹ Files modified: 2
✓ Label application complete!
ℹ Backups saved in: backups
```

#### Example 3: Bulk Processing

```powershell
# Process all assembly files in src/asm/
.\apply_labels.ps1 `
	-InputFile labels_batch1.csv `
	-SourceFiles "src/asm/*.asm" `
	-Verify `
	-Verbose
```

### Workflow

1. **Prepare label mappings** - Create CSV or JSON file with address-to-label mappings
2. **Test with dry run** - Use `-DryRun` to preview changes
3. **Apply labels** - Run without `-DryRun` to apply changes
4. **Verify integrity** - Use `-Verify` to ensure ROM still builds correctly
5. **Review backups** - Check backups in `backups/` directory if needed

### Best Practices

✅ **Always dry-run first** - Preview changes before applying  
✅ **Use verification** - Ensure ROM integrity with `-Verify`  
✅ **Start small** - Process one file at a time initially  
✅ **Check backups** - Backups are automatically created  
✅ **Follow conventions** - Use labels from `docs/LABEL_CONVENTIONS.md`  
✅ **Version control** - Commit before and after label application  

### Troubleshooting

**No replacements found:**
- Check address format matches usage in source (direct vs absolute vs long)
- Verify addresses exist in target files
- Use `-Verbose` to see detailed matching

**ROM verification failed:**
- Review recent changes in backups
- Check if labels were applied to data tables (not just code)
- Ensure label definitions match usage

**Build errors:**
- Verify label definitions exist in include files
- Check for typos in label names
- Ensure addressing modes are correct

### Label Naming Conventions

Follow the conventions defined in `docs/LABEL_CONVENTIONS.md`:

- **RAM variables**: lowercase with underscores, `!` prefix in code
- **ROM data**: UPPERCASE with type prefix (DATA_, TBL_, etc.)
- **Multi-byte**: Use `_lo`, `_hi`, `_bank` suffixes

**Examples:**
```assembly
!player_x_pos_lo        ; Direct page RAM (low byte)
!player_x_pos_hi        ; Direct page RAM (high byte)
!player_x_pos           ; Word address
DATA_07_WeaponStats:    ; ROM data table
```

### Related Documentation

- `docs/LABEL_CONVENTIONS.md` - Official labeling standards
- `docs/RAM_LABELS.md` - Complete RAM address documentation
- `docs/LABEL_GUIDE.md` - Guide to effective labeling
- `src/include/ffmq_ram_variables.inc` - Current label definitions

---

## Other Tools

*(More tools will be added to this directory as the project progresses)*

### Coming Soon

- **extract_labels.ps1** - Extract labels from existing code
- **validate_labels.ps1** - Validate label consistency
- **generate_map.ps1** - Generate memory map documentation

---

**Questions or Issues?**  
Open an issue on the project repository with the `type: tools` label.

**Last Updated:** November 1, 2025  
**Issue:** #27 - Memory Labels: Label Replacement Tool Development
