# FFMQ Tools Directory

> **📖 Complete Tool Documentation:** See [TOOLS_REFERENCE.md](../docs/TOOLS_REFERENCE.md) for comprehensive documentation of all 130+ Python and PowerShell tools.

This directory contains tools for ROM hacking, modding, and disassembly.

## Quick Links

- **[Complete Tools Reference](../docs/TOOLS_REFERENCE.md)** - Full documentation of all tools
- **[Enemy Editor Guide](../docs/ENEMY_EDITOR_GUIDE.md)** - Visual enemy editor tutorial
- **[Battle Data Pipeline](../docs/BATTLE_DATA_PIPELINE.md)** - Battle data workflow
- **[Graphics Quickstart](../docs/graphics-quickstart.md)** - Graphics tools guide

## Table of Contents

### Battle Data Modding Tools
1. [Enemy Editor GUI](#enemy-editor-gui) - Visual enemy editor ⭐
2. [Enemy Stats Viewer](#enemy-stats-viewer) - Quick command-line stats viewer
3. [ROM Comparison](#rom-comparison) - Compare ROM differences
4. [Build & Compare](#build--compare) - Automated build workflow
5. [Test Suite](#test-suite) - Master test runner
6. [Data Pipeline](#data-pipeline) - Extract, convert, integrate battle data

### Disassembly Tools
7. [Address Scanner](#address-scanner) - Scan and catalog all raw memory addresses
8. [ROM Data Catalog](#rom-data-catalog) - Catalog all DATA8/DATA16/ADDR labels
9. [Label Application Tool](#label-application-tool) - Apply labels to assembly files

---

## Battle Data Modding Tools

Complete toolkit for editing enemy stats, attacks, and battle data in FFMQ.

### Enemy Editor GUI

**File:** `enemy_editor_gui.py`  
**Launcher:** `enemy_editor.bat` (Windows) / `enemy_editor.sh` (Linux/Mac)  
**Documentation:** `docs/ENEMY_EDITOR_GUIDE.md`

#### Purpose

Visual GUI for editing all 83 enemies in Final Fantasy Mystic Quest with real-time validation, undo/redo support, and built-in testing.

#### Features

✅ **Visual editing** - Browse all enemies with search and filtering  
✅ **Intuitive controls** - Sliders and spinboxes for all stats  
✅ **Element editor** - Visual selection for resistances/weaknesses  
✅ **Undo/redo** - Full undo history (Ctrl+Z/Ctrl+Y)  
✅ **GameFAQs validation** - Verify accuracy against community data  
✅ **Pipeline testing** - Test data extraction and conversion  
✅ **Export options** - Save JSON or generate ASM directly

#### Quick Start

```bash
# Windows
enemy_editor.bat

# Linux/Mac
./enemy_editor.sh

# Or directly
python tools/enemy_editor_gui.py
```

#### Workflow

1. **Browse** - Select enemy from list or search by name
2. **Edit** - Modify stats using sliders/spinboxes
3. **Save** - Click "Save Enemy" or press Ctrl+S
4. **Export** - Generate JSON (Ctrl+E) for ROM building
5. **Test** - Verify with built-in GameFAQs check

---

### Enemy Stats Viewer

**File:** `view_enemy.py`

#### Purpose

Command-line tool for quickly viewing enemy stats without opening the GUI.

#### Quick Start

```bash
# View specific enemy
python tools/view_enemy.py Brownie

# View by ID
python tools/view_enemy.py 0

# List all enemies
python tools/view_enemy.py --list

# Search for enemies
python tools/view_enemy.py --search slime

# Brief output (basic stats only)
python tools/view_enemy.py Brownie --brief
```

#### Output Example

```
Enemy #000: Brownie
BASIC STATS:
  HP:              50
  Attack:           3
  Defense:          1
  Speed:            3
  Magic:            1
LEVEL & REWARDS:
  Level:            1
  XP Multiplier:   22
  GP Multiplier:    1
RESISTANCES: None
WEAKNESSES: None
```

---

### ROM Comparison

**File:** `compare_roms.py`

#### Purpose

Compare two SNES ROM files byte-by-byte with region identification and detailed difference reporting.

#### Features

✅ **Byte comparison** - Find all differences between ROMs  
✅ **Region mapping** - Identify changed sections (Enemy Stats, Attack Data, etc.)  
✅ **Hex dumps** - View exact byte differences  
✅ **Statistics** - Count and percentage of changes  
✅ **Grouping** - Group consecutive byte differences

#### Quick Start

```bash
# Basic comparison
python tools/compare_roms.py original.sfc modified.sfc

# Show hex dumps of differences
python tools/compare_roms.py rom1.sfc rom2.sfc --verbose

# Group by known regions
python tools/compare_roms.py rom1.sfc rom2.sfc --regions

# Full analysis
python tools/compare_roms.py rom1.sfc rom2.sfc --verbose --regions
```

#### Known Regions

- Enemy Stats Data (`$014275-$01469F`)
- Enemy Levels Data (`$01417C-$0141FC`)
- Attack Data (`$014678-$014776`)
- Text Data
- Graphics Data

---

### Build & Compare

**File:** `build_and_compare.py`

#### Purpose

Automated workflow tool that builds a modified ROM and compares it with the previous build to show what changed.

#### Workflow

1. **Backup** - Creates `.backup` of current ROM
2. **Convert** - Runs JSON → ASM conversion
3. **Build** - Executes build script
4. **Compare** - Shows differences vs backup
5. **Cleanup** - Optionally removes backup

#### Quick Start

```bash
# Build and compare
python tools/build_and_compare.py

# Show detailed differences
python tools/build_and_compare.py --verbose

# Keep backup file
python tools/build_and_compare.py --keep-temp
```

#### Output Example

```
[INFO] Creating backup: build/ffmq-rebuilt.sfc.backup
[INFO] Converting battle data...
[OK] Conversion complete
[INFO] Building ROM...
[OK] Build complete
[INFO] Comparing ROMs...
[OK] Found 127 bytes different (0.02%)
[INFO] Differences by region:
  - Enemy Stats: 127 bytes changed
```

---

### Test Suite

**File:** `run_all_tests.py`

#### Purpose

Master test suite runner for validating the complete battle data pipeline.

#### Test Categories

**Pipeline Tests** (`--category pipeline`)
- Enemy data extraction
- JSON modification
- JSON → ASM conversion
- Complete round-trip workflow

**GameFAQs Verification** (`--category gamefaqs`)
- Community data validation
- HP value accuracy
- Cross-reference with DrProctor's guide

**Build Integration** (`--category build`)
- ROM data verification
- Address mapping validation
- All 83 enemies present in ROM

#### Quick Start

```bash
# Run all tests
python tools/run_all_tests.py

# Run specific category
python tools/run_all_tests.py --category pipeline
python tools/run_all_tests.py --category gamefaqs
python tools/run_all_tests.py --category build

# Verbose output
python tools/run_all_tests.py --verbose
```

#### Output Example

```
Running test category: all
✓ Pipeline End-to-End Tests PASSED (REQUIRED)
✓ GameFAQs Data Verification PASSED (OPTIONAL)
✓ Build Integration Verification PASSED (REQUIRED)

All 3 test suites passing!
```

---

### Data Pipeline

Complete workflow for extracting, converting, and integrating battle data.

#### Extraction Tools

**Location:** `tools/extraction/`

```bash
# Extract enemy stats
python tools/extraction/extract_enemies.py roms/your-rom.sfc

# Extract attack data
python tools/extraction/extract_attacks.py roms/your-rom.sfc

# Extract enemy-attack links
python tools/extraction/extract_enemy_attack_links.py roms/your-rom.sfc
```

**Output:** JSON files in `data/extracted/`

#### Conversion Tools

**Location:** `tools/conversion/`

```bash
# Convert all data (recommended)
python tools/conversion/convert_all.py

# Or convert individually
python tools/conversion/convert_enemies.py
python tools/conversion/convert_attacks.py
python tools/conversion/convert_enemy_attack_links.py
```

**Output:** Assembly files in `data/converted/`

#### Verification Tools

```bash
# Test complete pipeline
python tools/test_pipeline.py

# Verify GameFAQs accuracy
python tools/verify_gamefaqs_data.py

# Verify ROM integration
python tools/verify_build_integration.py
```

---

## Complete Modding Workflow

### Quick Start (3 Steps)

```bash
# 1. Edit enemies
enemy_editor.bat

# 2. Build ROM
pwsh -File build.ps1

# 3. Test in emulator
mesen build/ffmq-rebuilt.sfc
```

### Development Workflow

```bash
# 1. Extract data from ROM
python tools/extraction/extract_enemies.py roms/ffmq.sfc

# 2. Modify JSON
# (edit data/extracted/enemies/enemies.json)

# 3. Convert to ASM
python tools/conversion/convert_all.py

# 4. Test pipeline
python tools/test_pipeline.py

# 5. Build and compare
python tools/build_and_compare.py --verbose

# 6. Run all tests
python tools/run_all_tests.py
```

### Tool Quick Reference

| Tool | Command | Purpose |
|------|---------|---------|
| Enemy Editor | `enemy_editor.bat` | Visual enemy editing |
| Stats Viewer | `python tools/view_enemy.py Brownie` | Quick stats lookup |
| Test Suite | `python tools/run_all_tests.py` | Run all tests |
| Build & Compare | `python tools/build_and_compare.py` | Automated build workflow |
| ROM Compare | `python tools/compare_roms.py rom1.sfc rom2.sfc` | Compare ROMs |
| Convert All | `python tools/conversion/convert_all.py` | JSON → ASM |

---

## Disassembly Tools

Tools for analyzing and labeling the FFMQ disassembly.

---

## Address Scanner

**File:** `scan_addresses.ps1`  
**Issue:** #23 - Memory Labels: Address Inventory and Analysis

### Purpose

Scans all assembly files in the project to identify raw memory addresses, categorize them by type (WRAM, Hardware, ROM), count occurrences, and generate comprehensive reports for labeling prioritization.

### Features

✅ **Comprehensive scanning** - Analyzes all ASM files recursively  
✅ **Smart categorization** - Identifies WRAM, PPU, Hardware, and ROM addresses  
✅ **Usage tracking** - Counts occurrences of each unique address  
✅ **Priority assignment** - Ranks addresses by usage frequency and type  
✅ **Label suggestions** - Generates suggested label names based on address type  
✅ **CSV reports** - Outputs detailed analysis in CSV format  

### Quick Start

```powershell
# Basic scan with default settings
.\scan_addresses.ps1

# Scan with verbose output
.\scan_addresses.ps1 -VerboseOutput

# Scan custom source path
.\scan_addresses.ps1 -SourcePath "C:\myproject\src"

# Custom output location
.\scan_addresses.ps1 -OutputPath "C:\myproject\analysis\addresses.csv"
```

### Output Format

The tool generates `reports/address_usage_report.csv` with the following columns:

- **Address** - The memory address (e.g., `$0000`, `$2116`)
- **Type** - Category: WRAM, PPU, Hardware, ROM, Other
- **Category** - Detailed category (e.g., "Zero Page", "PPU Registers")
- **Occurrences** - Number of times the address appears in code
- **Priority** - Labeling priority: Critical, High, Medium, Low
- **Suggested_Label** - Auto-generated label suggestion
- **Example_Contexts** - Sample usage contexts from source files

### Priority Levels

**WRAM Addresses:**
- **Critical**: 50+ occurrences
- **High**: 20-49 occurrences
- **Medium**: 10-19 occurrences
- **Low**: <10 occurrences

**Hardware/PPU Addresses:**
- **High**: 10+ occurrences
- **Medium**: 5-9 occurrences
- **Low**: <5 occurrences

**ROM Addresses:**
- **High**: 100+ occurrences
- **Medium**: 50-99 occurrences
- **Low**: <50 occurrences

### Usage Example

```powershell
PS> .\scan_addresses.ps1

=== FFMQ Address Scanner ===
Scanning for raw memory addresses in assembly files

==> Scanning ASM files in: C:\ffmq-info\src
Found 68 ASM files
✓ Scanned 68 files
Found 192 unique addresses
==> Generating report: C:\ffmq-info\reports\address_usage_report.csv
✓ Report generated successfully

=== Summary Statistics ===
Total unique addresses: 192
  Hardware: 14
  PPU: 12
  ROM: 36
  WRAM: 123

By Priority:
  Critical: 1
  High: 7
  Medium: 16
  Low: 168

Top 10 Most-Used Addresses:
  $0000 (WRAM): 60 occurrences - var_0000
  $420b (Hardware): 26 occurrences - MDMAEN
  $2116 (PPU): 20 occurrences - VMADDL
  ...

✓ Complete! Report saved to: reports\address_usage_report.csv
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `SourcePath` | string | `../src` | Directory containing ASM files to scan |
| `OutputPath` | string | `../reports/address_usage_report.csv` | Output CSV file path |
| `VerboseOutput` | switch | false | Display detailed progress information |

### Known Hardware Registers

The scanner automatically recognizes standard SNES hardware registers and suggests their official names:

- **PPU Registers** (`$2100-$21ff`): INIDISP, BGMODE, VMAIN, VMADDL, CGADD, etc.
- **CPU Registers** (`$4200-$43ff`): NMITIMEN, MDMAEN, HDMAEN, etc.
- **Controller Ports** (`$4016-$4017`): JOYSER0, JOYSER1

### Integration with Label Application

The output CSV is compatible with the Label Application Tool (`apply_labels.ps1`):

```powershell
# 1. Scan addresses
.\scan_addresses.ps1

# 2. Edit the CSV to refine labels (optional)
# Edit reports/address_usage_report.csv

# 3. Apply labels using the CSV
.\apply_labels.ps1 -InputFile ..\reports\address_usage_report.csv -SourceFiles "..\src\asm\*.asm"
```

---

## ROM Data Catalog

**File:** `catalog_rom_data.ps1`  
**Issue:** #25 - Memory Labels: ROM Data Map Documentation

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
