# FFMQ Disassembly Tools

This directory contains automation tools for the FFMQ disassembly project.

## Table of Contents

1. [Address Scanner](#address-scanner) - Scan and catalog all raw memory addresses
2. [ROM Data Catalog](#rom-data-catalog) - Catalog all DATA8/DATA16/ADDR labels
3. [Label Application Tool](#label-application-tool) - Apply labels to assembly files

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
  $420B (Hardware): 26 occurrences - MDMAEN
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

- **PPU Registers** (`$2100-$21FF`): INIDISP, BGMODE, VMAIN, VMADDL, CGADD, etc.
- **CPU Registers** (`$4200-$43FF`): NMITIMEN, MDMAEN, HDMAEN, etc.
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
$7E0040,player_x_pos,RAM,Player X position (word)
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

#### Direct Page ($00-$FF)
```assembly
; Before
LDA $40
STA $41,X

; After  
LDA !player_x_pos_lo
STA !player_x_pos_hi,X
```

#### Absolute ($0000-$FFFF)
```assembly
; Before
LDA $7E40
INC $7E41,X

; After
LDA !player_x_pos
INC !player_y_pos,X
```

#### Long ($000000-$FFFFFF)
```assembly
; Before
LDA $7E0040
STA $7E0042,X

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
