# FFMQ Build Instructions

## Overview

This project supports two build systems:
1. **asar** - Current format (original syntax from Diztinguish)
2. **ca65** - Modern format (GNU toolchain compatible)

## Prerequisites

### For asar Build (Current)

**Download asar:**
- Download from: https://github.com/RPGHacker/asar/releases
- Latest version: v1.91 or newer
- Windows: Download `asar-windows.zip`
- Extract `asar.exe` to project root or add to PATH

**Alternative - Using make.bat:**
```batch
make.bat
```
The existing `make.bat` in the project root uses asar.

### For ca65 Build (Future)

**Install cc65 toolchain:**
- Download from: https://github.com/cc65/cc65/releases
- Windows: Download `cc65-snapshot-win32.zip`
- Extract and add `bin/` directory to PATH
- Provides: ca65, ld65, od65

**Or use chocolatey:**
```powershell
choco install cc65
```

## Build Methods

### Method 1: Using asar Directly

**Build complete ROM:**
```bash
asar src/asm/ffmq_complete.asm build/ffmq-rebuilt.sfc
```

**Build with verbose output:**
```bash
asar -v src/asm/ffmq_complete.asm build/ffmq-rebuilt.sfc
```

**Build with symbol file:**
```bash
asar --symbols=wla build/symbols.sym src/asm/ffmq_complete.asm build/ffmq-rebuilt.sfc
```

### Method 2: Using make.bat (Windows)

The project includes `make.bat` which uses asar:

```batch
make.bat
```

This will:
1. Run asar on the source files
2. Generate output ROM
3. Show any assembly errors

### Method 3: Using Makefile (Future - ca65)

Once converted to ca65 syntax:

```bash
make rom          # Build ROM
make clean        # Clean build artifacts
make verify       # Verify ROM matches original
```

## Build Outputs

### Standard Build

```
build/
├── ffmq-rebuilt.sfc       # Rebuilt ROM file
├── symbols.sym            # Symbol file (if generated)
└── *.o                    # Object files (ca65 only)
```

### Build Artifacts

- **ROM File:** 1MB (1,048,576 bytes) - Same as original
- **Symbol File:** Labels for debugging in emulators
- **Object Files:** Intermediate assembly files (ca65)

## Verification

### Compare with Original ROM

**Using PowerShell:**
```powershell
$original = Get-FileHash "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" -Algorithm SHA256
$rebuilt = Get-FileHash "build\ffmq-rebuilt.sfc" -Algorithm SHA256
$original.Hash -eq $rebuilt.Hash
```

**Using certutil:**
```batch
certutil -hashfile "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" SHA256
certutil -hashfile "build\ffmq-rebuilt.sfc" SHA256
```

**Expected SHA256 (V1.1 US):**
```
TBD - Run hash on known good ROM
```

### Testing in Emulator

**Recommended emulators:**
- **MesenS** - Best accuracy, debugging features
- **bsnes-hd** - HD mode support, debugging
- **Snes9x** - Fast, widely compatible

**Load rebuilt ROM:**
```bash
mesen ffmq-rebuilt.sfc
```

## Current Build Status

### ✅ Ready to Build

- [x] All source files integrated
- [x] Diztinguish disassembly (16 banks)
- [x] Text engine
- [x] Graphics engine  
- [x] Macros and includes
- [x] Data files
- [x] Main assembly file (`ffmq_complete.asm`)

### 🔧 May Need Adjustments

- [ ] Include paths may need tweaking
- [ ] Some label references may need fixing
- [ ] Macro syntax may need adjustments
- [ ] Graphics data org directives may need refinement

### ⚠️ Known Issues

1. **asar Not Installed**
   - Solution: Download from https://github.com/RPGHacker/asar/releases
   - Extract `asar.exe` to project directory

2. **Include Path Errors**
   - Issue: `incsrc` directives may have wrong paths
   - Solution: Verify all paths in `ffmq_complete.asm`

3. **Label Conflicts**
   - Issue: Same label defined in multiple banks
   - Solution: Make labels local or namespace them

4. **Graphics Data**
   - Issue: Binary includes may need `incbin` directives
   - Solution: Verify all graphics file paths exist

## Troubleshooting

### Build Error: "File not found"

Check include paths in `ffmq_complete.asm`:
```asm
incsrc "../include/ffmq_macros_original.inc"   ; Correct relative path
incsrc "banks/bank_00.asm"                      ; Correct relative path
```

### Build Error: "Label already defined"

Make labels local using `.` prefix:
```asm
.local_label:          ; Local to current scope
global_label:          ; Global across all files
```

### Build Error: "Unknown instruction"

Check macro definitions are included:
```asm
incsrc "../include/ffmq_macros_original.inc"   ; Must be before use
```

### ROM Size Mismatch

Verify ROM is padded to 1MB:
```asm
; At end of ffmq_complete.asm
org $0fffff
db $ff
```

### Build Succeeds but ROM Doesn't Work

1. Compare file size: Should be exactly 1,048,576 bytes
2. Check ROM header at $00:FFC0-$00:FFD4
3. Verify checksum at $00:FFDE-$00:FFDF
4. Test in accurate emulator (MesenS, bsnes)

## Build Scripts

### Quick Build Script (build.ps1)

```powershell
# Build FFMQ ROM
param(
    [string]$Output = "build\ffmq-rebuilt.sfc",
    [switch]$Symbols,
    [switch]$Verbose
)

$asarArgs = @()
if ($Verbose) { $asarArgs += "-v" }
if ($Symbols) { $asarArgs += "--symbols=wla", "build\symbols.sym" }
$asarArgs += "src\asm\ffmq_complete.asm", $Output

& asar @asarArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful: $Output" -ForegroundColor Green
    $size = (Get-Item $Output).Length
    Write-Host "   Size: $size bytes (expected: 1048576)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
}
```

**Usage:**
```powershell
.\build.ps1                    # Basic build
.\build.ps1 -Verbose           # Verbose output
.\build.ps1 -Symbols           # Generate symbols
.\build.ps1 -Output test.sfc   # Custom output
```

## Next Steps

1. **Install asar:**
   ```powershell
   # Download asar from GitHub releases
   # Extract to project root or PATH
   ```

2. **First build attempt:**
   ```bash
   asar src/asm/ffmq_complete.asm build/ffmq-test.sfc
   ```

3. **Fix any errors:**
   - Note missing files
   - Fix include paths
   - Resolve label conflicts

4. **Verify build:**
   ```bash
   # Check file size
   # Compare with original
   # Test in emulator
   ```

5. **Document results:**
   - Update this file with any fixes
   - Note any changes needed
   - Track build progress

## Resources

- **asar Documentation:** https://rpghacker.github.io/asar/
- **ca65 Documentation:** https://cc65.github.io/doc/ca65.html
- **SNES Assembly Tutorial:** https://ersanio.gitbook.io/assembly-for-the-snes
- **65816 Opcodes:** http://www.6502.org/tutorials/65c816opcodes.html

---

*Last Updated: 2025-10-24*
*Status: Ready for first build attempt*
