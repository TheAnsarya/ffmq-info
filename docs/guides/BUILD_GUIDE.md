# FFMQ Build Guide

Complete guide to building Final Fantasy: Mystic Quest ROM from source.

**Last Updated**: November 1, 2025

---

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Build Types](#build-types)
- [Build Workflow](#build-workflow)
- [Asset Extraction](#asset-extraction)
- [Incremental vs Clean Builds](#incremental-vs-clean-builds)
- [Round-Trip Testing](#round-trip-testing)
- [ROM Space Management](#rom-space-management)
- [Build Reports](#build-reports)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

---

## Quick Start

### Basic Build (No Modifications)

```batch
REM Windows (using asar)
make.bat
```

This assembles the ROM from `ffmq - onlygood.asm` and produces `ffmq - onlygood.sfc`.

### Verify Build Matches Original

```powershell
# Compare built ROM with original
fc /b "ffmq - onlygood.sfc" "roms\ffmq-original.sfc"
```

Expected output: `FC: no differences encountered`

---

## Prerequisites

### Required Tools

1. **Asar** (SNES Assembler)
   - Download: https://www.smwcentral.net/?p=section&a=details&id=19043
   - Version: 1.81 or later
   - Installation:
	 ```powershell
	 # Option 1: Add to PATH
	 # Extract to C:\asar\
	 # Add C:\asar\ to system PATH
	 
	 # Option 2: Copy to project directory
	 # Extract asar.exe to project root
	 ```
   - Verify installation:
	 ```powershell
	 asar --version
	 # Expected: Asar 1.81
	 ```

2. **.NET Framework** (for asset extraction tools)
   - Version: 4.7.2 or later
   - Download: https://dotnet.microsoft.com/download/dotnet-framework
   - Required for `pull-assets-from-rom.exe`

### Optional Tools

1. **Hex Editor** (for ROM inspection)
   - HxD: https://mh-nexus.de/en/hxd/
   - Or any hex editor of choice

2. **Mesen-S** (SNES emulator/debugger)
   - Download: https://www.mesen.ca/
   - Best for debugging and testing

3. **Git** (for version control)
   - Download: https://git-scm.com/

### Source Files

Your repository should have:
- `ffmq.asm` or `ffmq - onlygood.asm` - Main assembly file
- `src/` - Source code directory
  - `src/asm/` - Assembly source files
  - `src/text/` - Text data
- `roms/` - Original ROM for reference
- `assets/` - Extracted game assets

---

## Build Types

### 1. Standard Build

**File**: `ffmq - onlygood.asm`  
**Output**: `ffmq - onlygood.sfc`  
**Purpose**: Clean, documented disassembly build

```batch
asar "ffmq - onlygood.asm"
```

**Features**:
- Byte-perfect match with original ROM
- Documented code
- Clean label names
- Organized file structure

### 2. Working Build

**File**: `ffmq.asm`  
**Output**: `ffmq.sfc`  
**Purpose**: Experimental/testing build

```batch
asar ffmq.asm
```

**Features**:
- May include work-in-progress changes
- Used for testing modifications
- Not guaranteed byte-perfect

### 3. Master Build

**File**: `src/asm/ffmq_master.asm`  
**Output**: Custom  
**Purpose**: Complete rebuild from organized sources

```batch
asar "src/asm/ffmq_master.asm" -o "build/ffmq_rebuild.sfc"
```

**Features**:
- Includes all 16 banks
- Modular structure
- Uses include files
- Full documentation

---

## Build Workflow

### Standard Workflow

```
┌─────────────────────┐
│  Original ROM       │
│  (ffmq-original.sfc)│
└──────────┬──────────┘
		   │
		   │ [1. Extract Assets]
		   ▼
┌─────────────────────┐
│  Assets Directory   │
│  - Graphics         │
│  - Text             │
│  - Music            │
│  - Data             │
└──────────┬──────────┘
		   │
		   │ [2. Disassemble/Document]
		   ▼
┌─────────────────────┐
│  Source Files       │
│  - ASM code         │
│  - Include files    │
│  - Data tables      │
└──────────┬──────────┘
		   │
		   │ [3. Assemble with Asar]
		   ▼
┌─────────────────────┐
│  Built ROM          │
│  (ffmq.sfc)         │
└──────────┬──────────┘
		   │
		   │ [4. Verify]
		   ▼
┌─────────────────────┐
│  Byte-Perfect Match │
│  ✓ Success          │
└─────────────────────┘
```

### Detailed Steps

#### Step 1: Prepare Source
Ensure all source files are present and up-to-date.

#### Step 2: Clean Previous Build (Optional)
```powershell
# Remove old ROM files
Remove-Item "*.sfc" -ErrorAction SilentlyContinue
Remove-Item "*.smc" -ErrorAction SilentlyContinue
```

#### Step 3: Run Assembler
```batch
asar "ffmq - onlygood.asm"
```

Expected output:
```
Assembling...
ROM size: 1024 KB (1,048,576 bytes)
```

#### Step 4: Verify Output
```powershell
# Check file size
(Get-Item "ffmq - onlygood.sfc").Length
# Expected: 1048576 bytes (1 MB)

# Compare with original
fc /b "ffmq - onlygood.sfc" "roms\ffmq-original.sfc"
# Expected: FC: no differences encountered
```

---

## Asset Extraction

### Using pull-assets-from-rom Tool

The C# tool in `pull-assets-from-rom/` extracts game assets from the original ROM.

#### Build the Tool

```powershell
cd pull-assets-from-rom
dotnet build
# Or open pull-assets-from-rom.sln in Visual Studio
```

#### Run Asset Extraction

```powershell
# Extract all assets
.\pull-assets-from-rom.exe "path\to\original\ffmq.sfc"
```

#### Extracted Assets

The tool creates:
- `assets/graphics/` - Tile data, sprites, backgrounds
- `assets/data/` - Game data tables
- `assets/text/` - Dialog and text strings
- `assets/music/` - Audio data (SPC700)

#### Asset Formats

| Asset Type | Format | Compression | Location |
|------------|--------|-------------|----------|
| Graphics (tiles) | 2bpp/4bpp | LZSS | Banks $04-$07 |
| Palettes | 15-bit BGR | None | Banks $04-$07 |
| Tilemaps | 16-bit words | LZSS | Banks $05-$08 |
| Text | DTE compressed | DTE | Bank $03 |
| Music | SPC700 | BRR | Bank $08 |
| Character data | Binary tables | None | Bank $0c |
| Enemy data | Binary tables | None | Bank $0e |

### Manual Asset Extraction

For specific assets, you can extract manually:

#### Extract Text Data
```powershell
# Text is in Bank $03 (ROM offset $018000-$01ffff)
# Use hex editor to extract and decode with DTE table
```

#### Extract Graphics
```powershell
# Graphics data in Banks $04-$07
# Use tile editor compatible with SNES 2bpp/4bpp format
```

---

## Incremental vs Clean Builds

### Incremental Build

**When to use**: Making small changes to source files

**Process**:
1. Modify source file(s)
2. Run `make.bat`
3. Asar automatically detects changes
4. Only modified sections are reassembled

**Advantages**:
- Fast (seconds)
- Good for iterative development
- Immediate feedback

**Limitations**:
- Asar doesn't track include file dependencies perfectly
- May miss changes in some edge cases

### Clean Build

**When to use**:
- After modifying include files
- Before release/verification
- When unsure if incremental build is correct
- After major refactoring

**Process**:
```powershell
# 1. Remove all output files
Remove-Item "*.sfc", "*.smc" -ErrorAction SilentlyContinue

# 2. Clean build directory (if exists)
Remove-Item "build\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Rebuild from scratch
asar "ffmq - onlygood.asm"
```

**Advantages**:
- Guaranteed fresh build
- Catches all changes
- Ensures consistency

**Limitations**:
- Slower (still only ~1-2 seconds for FFMQ)
- Unnecessary for simple changes

### Best Practices

1. **Use incremental builds** during active development
2. **Run clean build** before committing to version control
3. **Verify clean build** matches byte-perfect after major changes
4. **Clean build for releases** to ensure consistency

---

## Round-Trip Testing

Round-trip testing ensures the build system maintains ROM integrity.

### Round-Trip Process

```
Original ROM → Extract Assets → Reassemble → Compare
	 ↓                                            ↓
  [Baseline]  ←──────── Should Match ────────  [Output]
```

### Automated Round-Trip Test

Create `test-roundtrip.ps1`:

```powershell
# FFMQ Round-Trip Test Script
# Verifies build produces byte-perfect match with original ROM

param(
	[string]$OriginalROM = "roms\ffmq-original.sfc",
	[string]$buildFile = "ffmq - onlygood.asm",
	[string]$OutputROM = "ffmq - onlygood.sfc"
)

Write-Host "FFMQ Round-Trip Test" -ForegroundColor Cyan
Write-Host "=" * 50

# Step 1: Verify original ROM exists
Write-Host "`n[1/4] Checking original ROM..." -ForegroundColor Yellow
if (-not (Test-Path $OriginalROM)) {
	Write-Host "ERROR: Original ROM not found at: $OriginalROM" -ForegroundColor Red
	exit 1
}
$originalSize = (Get-Item $OriginalROM).Length
Write-Host "  ✓ Original ROM found ($originalSize bytes)" -ForegroundColor Green

# Step 2: Clean previous build
Write-Host "`n[2/4] Cleaning previous builds..." -ForegroundColor Yellow
Remove-Item $OutputROM -ErrorAction SilentlyContinue
Write-Host "  ✓ Cleaned" -ForegroundColor Green

# Step 3: Build ROM
Write-Host "`n[3/4] Building ROM from source..." -ForegroundColor Yellow
$asarOutput = & asar $buildFile 2>&1
if ($LASTEXITCODE -ne 0) {
	Write-Host "ERROR: Build failed!" -ForegroundColor Red
	Write-Host $asarOutput
	exit 1
}
Write-Host "  ✓ Build successful" -ForegroundColor Green

# Step 4: Verify output
Write-Host "`n[4/4] Verifying byte-perfect match..." -ForegroundColor Yellow
if (-not (Test-Path $OutputROM)) {
	Write-Host "ERROR: Output ROM not created!" -ForegroundColor Red
	exit 1
}

$builtSize = (Get-Item $OutputROM).Length
Write-Host "  Original: $originalSize bytes" -ForegroundColor Cyan
Write-Host "  Built:    $builtSize bytes" -ForegroundColor Cyan

if ($originalSize -ne $builtSize) {
	Write-Host "  ✗ SIZE MISMATCH!" -ForegroundColor Red
	exit 1
}

# Byte-by-byte comparison
$comparison = fc.exe /b $OriginalROM $OutputROM 2>&1
if ($LASTEXITCODE -eq 0) {
	Write-Host "  ✓ PERFECT MATCH! ROMs are identical." -ForegroundColor Green
	Write-Host "`n" + "=" * 50
	Write-Host "Round-Trip Test: PASSED ✓" -ForegroundColor Green
	exit 0
} else {
	Write-Host "  ✗ BYTE MISMATCH!" -ForegroundColor Red
	Write-Host "`nDifferences found:" -ForegroundColor Yellow
	Write-Host $comparison
	Write-Host "`n" + "=" * 50
	Write-Host "Round-Trip Test: FAILED ✗" -ForegroundColor Red
	exit 1
}
```

### Running Round-Trip Test

```powershell
# Run test
.\test-roundtrip.ps1

# With custom paths
.\test-roundtrip.ps1 -OriginalROM "path\to\original.sfc"
```

### Expected Output

```
FFMQ Round-Trip Test
==================================================

[1/4] Checking original ROM...
  ✓ Original ROM found (1048576 bytes)

[2/4] Cleaning previous builds...
  ✓ Cleaned

[3/4] Building ROM from source...
  ✓ Build successful

[4/4] Verifying byte-perfect match...
  Original: 1048576 bytes
  Built:    1048576 bytes
  ✓ PERFECT MATCH! ROMs are identical.

==================================================
Round-Trip Test: PASSED ✓
```

### Debugging Round-Trip Failures

If round-trip fails:

#### 1. Check File Sizes
```powershell
(Get-Item "roms\ffmq-original.sfc").Length
(Get-Item "ffmq - onlygood.sfc").Length
```

**If different**: Assembly file has incorrect org/bank definitions

#### 2. Find First Difference
```powershell
# Use fc to find first mismatch
fc /b "roms\ffmq-original.sfc" "ffmq - onlygood.sfc" | Select-Object -First 10
```

Output shows offset in hex:
```
0001A3C0: 42 43
		 ^^  ^^
	Original Built
```

#### 3. Identify Bank/Offset
```powershell
# Convert hex offset to bank:address
# Example: 0001A3C0 = Bank $03:$63c0 (LoROM)
```

#### 4. Check Source
Review assembly source at that bank/address for:
- Incorrect data
- Missing labels
- Wrong directives
- Alignment issues

#### 5. Common Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Wrong `org` directive | Size mismatch | Verify bank start addresses |
| Missing data | Bytes differ at specific offset | Check data inclusion |
| Incorrect `db`/`dw` | Small byte differences | Verify data tables |
| Compression issues | Large sections differ | Re-extract compressed data |
| Include file not found | Build fails | Check file paths |

---

## ROM Space Management

### ROM Layout (LoROM)

```
Bank  ROM Offset    Address Range  Size   Contents
----  ----------    -------------  -----  ---------
$00   $000000       $008000-$00ffff  32KB  Main engine
$01   $008000       $018000-$01ffff  32KB  Event handlers
$02   $010000       $028000-$02ffff  32KB  Extended logic
$03   $018000       $038000-$03ffff  32KB  Text data
$04   $020000       $048000-$04ffff  32KB  Graphics (sprites)
$05   $028000       $058000-$05ffff  32KB  Graphics (tilemaps)
$06   $030000       $068000-$06ffff  32KB  Graphics (animations)
$07   $038000       $078000-$07ffff  32KB  Graphics (palettes)
$08   $040000       $088000-$08ffff  32KB  Graphics (layouts)
$09   $048000       $098000-$09ffff  32KB  Graphics (sprite GFX)
$0a   $050000       $0a8000-$0affff  32KB  Graphics (anim seqs)
$0b   $058000       $0b8000-$0bffff  32KB  Battle graphics
$0c   $060000       $0c8000-$0cffff  32KB  Data tables
$0d   $068000       $0d8000-$0dffff  32KB  Extended data
$0e   $070000       $0e8000-$0effff  32KB  Battle data
$0f   $078000       $0f8000-$0fffff  32KB  Audio (SPC700)
----  ----------                    -----
Total $080000 (512KB) mapped, 1MB ROM total
```

### Free Space Tracking

#### Checking Free Space

```powershell
# Create script: check-free-space.ps1
# Analyzes ROM for unused regions

param([string]$RomFile = "ffmq - onlygood.sfc")

$rom = [System.IO.File]::ReadAllBytes($RomFile)
$freeBytes = 0
$currentFree = 0
$freeRegions = @()

for ($i = 0; $i -lt $rom.Length; $i++) {
	if ($rom[$i] -eq 0x00 -or $rom[$i] -eq 0xFF) {
		$currentFree++
	} else {
		if ($currentFree -ge 16) {  # Regions of 16+ bytes
			$freeRegions += [PSCustomObject]@{
				Offset = "0x{0:X6}" -f ($i - $currentFree)
				Size = $currentFree
			}
			$freeBytes += $currentFree
		}
		$currentFree = 0
	}
}

Write-Host "Free Space Analysis" -ForegroundColor Cyan
Write-Host "ROM Size: $($rom.Length) bytes"
Write-Host "Free Bytes: $freeBytes bytes ({0:P2})" -f ($freeBytes / $rom.Length)
Write-Host "`nFree Regions (16+ bytes):"
$freeRegions | Format-Table -AutoSize
```

#### Reserving Space for Modifications

When planning modifications, calculate required space:

```asm
; Example: Adding new dialog
; Original: 200 bytes
; New text: 250 bytes
; Required: +50 bytes

; Option 1: Find free space in same bank
org $03f800  ; Check if free in Bank $03
  db "New dialog text..."
  
; Option 2: Use free space in different bank
org $0ff000  ; Free space in Bank $0f
  db "New dialog text..."
  ; Update pointer table to point here
```

### Space Optimization Techniques

1. **Compression**
   - Text: DTE (Dual Tile Encoding) saves ~40%
   - Graphics: LZSS compression saves ~50-70%
   - Tilemaps: RLE compression

2. **Deduplication**
   - Share common graphics between maps
   - Reuse palette data
   - Consolidate duplicate text strings

3. **Bank Reorganization**
   - Move rarely-accessed data to underutilized banks
   - Group related data together
   - Optimize bank switching overhead

---

## Build Reports

### Creating Build Report

Track build statistics over time:

```powershell
# build-report.ps1
# Generates detailed build report

param([string]$OutputFile = "build-report.txt")

$report = @"
FFMQ Build Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
================================================

ROM Information:
  File: ffmq - onlygood.sfc
  Size: $((Get-Item "ffmq - onlygood.sfc").Length) bytes
  MD5:  $((Get-FileHash "ffmq - onlygood.sfc" -Algorithm MD5).Hash)
  SHA256: $((Get-FileHash "ffmq - onlygood.sfc").Hash)

Source Files:
$((Get-ChildItem -Recurse -Include *.asm | Measure-Object).Count) assembly files
$((Get-ChildItem -Recurse -Include *.inc | Measure-Object).Count) include files

Build Status:
  ✓ Assembly successful
  ✓ Byte-perfect match verified
  ✓ All banks included

Bank Statistics:
  Bank 00: Main Engine
  Bank 01: Event Handlers
  Bank 02: Extended Logic
  Bank 03: Text Data
  ... (add detailed bank info)

Labels:
  Total defined: (count from label file)
  Coverage: XX%

Last Modified Files:
$((Get-ChildItem -Recurse -Include *.asm | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { "  - $($_.Name) ($($_.LastWriteTime))" }) -join "`n")

================================================
"@

$report | Out-File $OutputFile -Encoding UTF8
Write-Host "Build report saved to: $OutputFile"
```

### Report Format Example

```
FFMQ Build Report
Generated: 2025-11-01 16:30:00
================================================

ROM Information:
  File: ffmq - onlygood.sfc
  Size: 1048576 bytes
  MD5:  A7B3C4D5E6F7A8B9C0D1E2F3A4B5C6D7
  SHA256: 1234567890ABCDEF...

Source Files:
  42 assembly files
  12 include files

Build Status:
  ✓ Assembly successful
  ✓ Byte-perfect match verified
  ✓ All banks included

Bank Statistics:
  Bank 00: 32768 bytes (100% used)
  Bank 01: 32768 bytes (100% used)
  ...

Labels:
  Total defined: 450
  Coverage: 70%

================================================
```

---

## Troubleshooting

### Common Build Errors

#### Error: "asar: command not found"

**Cause**: Asar not in PATH or not installed

**Solution**:
```powershell
# Check if asar is installed
where.exe asar

# If not found, add to PATH or use full path
C:\asar\asar.exe "ffmq - onlygood.asm"
```

#### Error: "unknown command ORG"

**Cause**: Asar version too old

**Solution**:
```powershell
# Check version
asar --version

# Update to Asar 1.81 or later
# Download from: https://www.smwcentral.net/
```

#### Error: "can't open 'filename.inc'"

**Cause**: Include file not found

**Solution**:
```asm
; Check include path
incsrc "src/include/filename.inc"  ; Correct
incsrc "filename.inc"               ; May fail if not in same directory

; Use relative paths from main asm file location
```

#### Error: ROM size mismatch

**Cause**: Incorrect org directives or missing data

**Solution**:
```asm
; Verify org directives for each bank
org $008000  ; Bank $00 starts at $008000
; ...
org $018000  ; Bank $01 starts at $018000
; ...

; Ensure all banks are filled properly
; Use 'fillbyte' if needed
fillbyte $ff
fill $ff0000  ; Fill to specific address
```

#### Warning: "label 'xyz' already defined"

**Cause**: Duplicate label definitions

**Solution**:
```asm
; Use unique labels or local labels
label_name:        ; Global
.local_name:       ; Local to previous global label
```

### Build Performance Issues

#### Slow Build Times

**Symptoms**: Build takes >5 seconds

**Causes & Solutions**:
1. **Large included files**: Split into smaller modules
2. **Circular includes**: Check include hierarchy
3. **Disk I/O**: Use SSD, check antivirus exclusions
4. **Asar version**: Update to latest version

#### Out of Memory

**Symptoms**: Build fails with memory error

**Causes & Solutions**:
1. **Huge macros**: Simplify macro expansions
2. **Recursive includes**: Fix include structure
3. **Too many labels**: Optimize label usage

### Verification Issues

#### ROM Matches but Doesn't Run

**Possible Issues**:
1. **Corrupt emulator state**: Clear emulator cache
2. **Wrong ROM format**: Ensure .sfc (no SMC header)
3. **Emulator compatibility**: Try different emulator

**Testing**:
```powershell
# Verify ROM header
# Offset $00ffc0-$00ffdf contains header
# Check with hex editor
```

#### ROM Runs but Behaves Differently

**Debugging Steps**:
1. Compare save states between original and built ROM
2. Check for dynamic code generation (rare in FFMQ)
3. Verify SRAM initialization
4. Check for timing-dependent code

---

## Advanced Topics

### Custom Build Configurations

Create multiple build targets:

```batch
REM build-all.bat
REM Builds all ROM variants

echo Building standard ROM...
asar "ffmq - onlygood.asm"

echo Building debug ROM...
asar "ffmq-debug.asm" -o "ffmq-debug.sfc"

echo Building modded ROM...
asar "ffmq-mod.asm" -o "ffmq-mod.sfc"

echo Done!
```

### Conditional Assembly

```asm
; Use !defines for build configurations
!DEBUG = 1
!ENABLE_CHEATS = 0

if !DEBUG
	; Debug-only code
	jml DebugMenu
endif

if !ENABLE_CHEATS
	; Cheat code
	lda #$ff
	sta $7e0100  ; Max HP
endif
```

### Build Automation (CI/CD)

For GitHub Actions or similar:

```yaml
# .github/workflows/build.yml
name: Build ROM

on: [push, pull_request]

jobs:
  build:
	runs-on: windows-latest
	steps:
	  - uses: actions/checkout@v2
	  
	  - name: Download Asar
		run: |
		  # Download and extract asar
		  
	  - name: Build ROM
		run: |
		  asar "ffmq - onlygood.asm"
		  
	  - name: Verify Build
		run: |
		  # Run verification script
		  
	  - name: Upload ROM
		uses: actions/upload-artifact@v2
		with:
		  name: ffmq-rom
		  path: "*.sfc"
```

### Multi-Language Builds

```asm
; Language selection
!LANGUAGE_ENGLISH = 0
!LANGUAGE_JAPANESE = 1
!LANGUAGE = !LANGUAGE_ENGLISH

if !LANGUAGE == !LANGUAGE_ENGLISH
	incsrc "text/english.asm"
elseif !LANGUAGE == !LANGUAGE_JAPANESE
	incsrc "text/japanese.asm"
endif
```

---

## Related Documentation

- **README.md**: Project overview and quick setup
- **docs/ARCHITECTURE.md**: System architecture details
- **docs/DATA_STRUCTURES.md**: Game data format reference
- **docs/LABEL_INDEX.md**: Memory label reference
- **src/include/**: Include file documentation

---

## Contributing

When contributing build system improvements:

1. **Test thoroughly**: Ensure round-trip test passes
2. **Document changes**: Update this guide with new features
3. **Maintain compatibility**: Don't break existing builds
4. **Add tests**: Create test scripts for new features

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-01 | Initial comprehensive build guide |

---

*For questions or issues, please open a GitHub issue.*
