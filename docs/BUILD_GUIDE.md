# Build Guide - FFMQ Disassembly Project

A comprehensive guide to building the Final Fantasy Mystic Quest ROM from source code.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Build Instructions](#detailed-build-instructions)
- [Build Options](#build-options)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Platform-Specific Notes](#platform-specific-notes)
- [Advanced Topics](#advanced-topics)

## Prerequisites

### Required Tools

1. **PowerShell 7.0+** (for build scripts)
   - Windows: [Download PowerShell](https://github.com/PowerShell/PowerShell/releases)
   - Linux/macOS: Included with most distributions or install via package manager

2. **asar Assembler** (for building the ROM)
   - Download: [asar Releases](https://github.com/RPGHacker/asar/releases)
   - Version: 1.81+ recommended
   - Place `asar.exe` in project root OR add to system PATH

3. **Git** (for version control)
   - Download: [Git SCM](https://git-scm.com/downloads)
   - Required for cloning repository and managing changes

### Optional Tools

4. **Python 3.8+** (for tooling and scripts)
   - Download: [Python.org](https://www.python.org/downloads/)
   - Used for graphics extraction, text tools, etc.

5. **Mesen-S Emulator** (for testing)
   - Download: [Mesen-S](https://github.com/SourMesen/Mesen-S/releases)
   - Best emulator for SNES development and debugging

6. **Visual Studio Code** (recommended IDE)
   - Download: [VS Code](https://code.visualstudio.com/)
   - Includes built-in tasks for formatting and building

### Original ROM

You need a legal copy of the original ROM:
- **File**: `Final Fantasy - Mystic Quest (U) (V1.1).sfc`
- **Size**: 1,048,576 bytes (1 MB)
- **SHA256**: (varies by version)
- **Location**: Place in `~roms/` directory

## Quick Start

**For the impatient** - minimal steps to build:

```powershell
# 1. Install asar assembler
# Download from https://github.com/RPGHacker/asar/releases
# Extract asar.exe to project root

# 2. Build the ROM
.\build.ps1

# 3. Output is in build/ffmq-rebuilt.sfc
```

That's it! For verification and testing, continue reading.

## Detailed Build Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/TheAnsarya/ffmq-info.git
cd ffmq-info
```

### Step 2: Install asar Assembler

**Option A: Place in Project Root**

1. Download latest asar from [GitHub Releases](https://github.com/RPGHacker/asar/releases)
2. Extract `asar.exe` (Windows) or `asar` (Linux/macOS)
3. Copy to project root directory

**Option B: Add to System PATH**

1. Download and extract asar
2. Add asar directory to your system PATH
3. Verify: `asar --version`

**Option C: Use tools/ Directory**

1. Create `tools/` directory if it doesn't exist
2. Place `asar.exe` in `tools/`
3. Build script will find it automatically

### Step 3: Verify Prerequisites

Run the setup script to check your environment:

```powershell
.\setup.ps1
```

This will:
- ✅ Check for required tools
- ✅ Verify asar installation
- ✅ Set up Python environment (if Python installed)
- ✅ Report any missing dependencies

### Step 4: Build the ROM

**Basic Build:**

```powershell
.\build.ps1
```

**With Verbose Output:**

```powershell
.\build.ps1 -Verbose
```

**Clean Build** (remove previous build files):

```powershell
.\build.ps1 -Clean
```

### Step 5: Verify the Build

The build script automatically:
- ✅ Checks output file size (should be 1 MB)
- ✅ Calculates SHA256 hash
- ✅ Compares with original ROM (if available)
- ✅ Reports match percentage

Look for:
```
✅ Assembly completed in X.XX seconds
✅ File size matches expected 1MB
```

### Step 6: Test the ROM

**In Mesen-S Emulator:**

```bash
mesen build/ffmq-rebuilt.sfc
```

**Test Checklist:**
- [ ] ROM loads without errors
- [ ] Title screen displays correctly
- [ ] Can start new game
- [ ] Controls work properly
- [ ] No graphical glitches

## Build Options

The build script (`build.ps1`) supports several options:

### Source File

```powershell
.\build.ps1 -Source "src\asm\custom_file.asm"
```

Specify a different source file to build. Default is `src\asm\ffmq_working.asm`.

### Output Location

```powershell
.\build.ps1 -Output "build\custom-rom.sfc"
```

Specify custom output path. Default is `build\ffmq-rebuilt.sfc`.

### Symbol File Generation

```powershell
.\build.ps1 -Symbols
```

Generates `build/symbols.sym` for debugging in emulators:
- Useful for debugging with Mesen-S
- Shows labels and addresses
- WLA-DX symbol format

### Verbose Mode

```powershell
.\build.ps1 -Verbose
```

Enables detailed assembly output:
- Shows each file being assembled
- Displays warnings
- Helpful for debugging assembly errors

### Clean Build

```powershell
.\build.ps1 -Clean
```

Removes all files in `build/` directory before building:
- Ensures fresh build
- Useful when switching branches
- Prevents stale artifacts

### Combined Options

```powershell
.\build.ps1 -Clean -Verbose -Symbols
```

All options can be combined as needed.

## Verification

### File Size Check

The built ROM **must** be exactly **1,048,576 bytes** (1 MB):

```powershell
(Get-Item build\ffmq-rebuilt.sfc).Length
# Should output: 1048576
```

If size differs:
- ❌ Too small: Missing data or padding
- ❌ Too large: Extra data or incorrect padding
- 🔧 Check your source files and includes

### Hash Verification

Compare with original ROM:

```powershell
# Calculate hash of built ROM
Get-FileHash build\ffmq-rebuilt.sfc -Algorithm SHA256

# Calculate hash of original
Get-FileHash ~roms\Final` Fantasy` -` Mystic` Quest` `(U`)` `(V1.1`).sfc -Algorithm SHA256

# Compare
```

**Note**: Perfect match is only expected when disassembly is 100% complete. During development, differences are normal.

### Emulator Testing

**Mesen-S** (recommended):
```bash
mesen build/ffmq-rebuilt.sfc
```

**SNES9x**:
```bash
snes9x build/ffmq-rebuilt.sfc
```

**bsnes**:
```bash
bsnes build/ffmq-rebuilt.sfc
```

### Quick Test Script

```powershell
# Run verification
.\tools\verify-build.ps1
```

This script:
- ✅ Checks file size
- ✅ Calculates hashes
- ✅ Compares with original
- ✅ Generates comparison report

## Troubleshooting

### Error: "asar assembler not found!"

**Problem**: Build script can't find asar

**Solutions**:
1. Download asar from [GitHub](https://github.com/RPGHacker/asar/releases)
2. Place `asar.exe` in project root
3. OR add asar to system PATH
4. OR place in `tools/` directory

**Verify**:
```powershell
# If in PATH:
asar --version

# If in project root:
.\asar.exe --version

# If in tools:
.\tools\asar.exe --version
```

### Error: "Assembly failed with exit code 1"

**Problem**: Syntax error or missing file in assembly source

**Solutions**:
1. Check error messages above the failure
2. Look for:
   - Missing include files
   - Label conflicts
   - Syntax errors
   - File not found errors
3. Review recent changes to source files

**Debug Steps**:
```powershell
# Build with verbose output
.\build.ps1 -Verbose

# Check specific file mentioned in error
# Fix syntax or include path
# Rebuild
```

### Error: "File size is XXX bytes (expected 1048576)"

**Problem**: ROM is not correctly sized/padded

**Causes**:
- Missing data sections
- Incorrect padding in source
- Assembly error

**Solutions**:
1. Check for missing `.org` directives
2. Verify all banks are included
3. Check padding at end of ROM
4. Review source file structure

### Error: "ROM differs from original"

**Problem**: Built ROM doesn't match original

**This is NORMAL during development!**

**Why**:
- Disassembly is not yet 100% complete
- Some sections use placeholder data
- Graphics/text not fully integrated

**When to worry**:
- ❌ ROM doesn't boot in emulator
- ❌ Crashes during gameplay
- ❌ Major graphical corruption
- ✅ Minor differences are OK during development

### Build is Slow

**Normal build time**: 2-10 seconds

**If slower**:
- Check antivirus (may scan built ROM)
- Disable real-time protection temporarily
- Add project to antivirus exclusions
- Use SSD instead of HDD

### PowerShell Execution Policy Error

**Problem**: "cannot be loaded because running scripts is disabled"

**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single script
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

## Platform-Specific Notes

### Windows

**Recommended Setup**:
- PowerShell 7+ (built-in with Windows 11)
- Place `asar.exe` in project root
- Use VS Code with PowerShell extension

**Path Separators**: Use backslash `\` in paths
```powershell
.\build.ps1 -Source "src\asm\file.asm"
```

**Line Endings**: CRLF (Windows standard)
- All ASM files use CRLF
- Git configured for CRLF on Windows

### Linux

**Prerequisites**:
```bash
# Install PowerShell
sudo apt install powershell  # Debian/Ubuntu
sudo dnf install powershell  # Fedora
```

**asar Installation**:
```bash
# Download Linux build
wget https://github.com/RPGHacker/asar/releases/download/v1.81/asar-linux.tar.gz
tar -xzf asar-linux.tar.gz
chmod +x asar
sudo mv asar /usr/local/bin/
```

**Running Build**:
```bash
pwsh ./build.ps1
```

**Path Separators**: Use forward slash `/` or backslash `\` (PowerShell accepts both)

### macOS

**Prerequisites**:
```bash
# Install PowerShell via Homebrew
brew install powershell

# Or download from GitHub
```

**asar Installation**:
```bash
# Download macOS build
# Extract and make executable
chmod +x asar
sudo mv asar /usr/local/bin/
```

**Running Build**:
```bash
pwsh ./build.ps1
```

**Apple Silicon (M1/M2)**:
- asar runs under Rosetta 2
- Performance is excellent
- No special configuration needed

## Advanced Topics

### Incremental Builds

The build system automatically:
- Detects which files changed
- Only reassembles modified banks
- Caches unchanged sections

**Force Full Rebuild**:
```powershell
.\build.ps1 -Clean
```

### Custom Build Scripts

Create your own build variations:

```powershell
# build-debug.ps1
.\build.ps1 -Symbols -Verbose -Output "build\ffmq-debug.sfc"

# build-release.ps1
.\build.ps1 -Clean -Output "build\ffmq-release.sfc"
```

### Integration with VS Code

Use built-in tasks (Ctrl+Shift+P → "Run Task"):

**Available Tasks**:
- **Build ROM**: Standard build
- **Build ROM (Clean)**: Clean build
- **Build ROM (Verbose)**: Verbose build
- **Verify Build**: Run verification tests

**Configure** (`.vscode/tasks.json`):
```json
{
    "label": "Build ROM",
    "type": "shell",
    "command": "pwsh",
    "args": ["-File", "${workspaceFolder}/build.ps1"],
    "group": {
        "kind": "build",
        "isDefault": true
    }
}
```

### Automated Testing

Set up automated build tests:

```powershell
# test-build.ps1
.\build.ps1 -Clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful"
    .\tools\verify-build.ps1
} else {
    Write-Host "❌ Build failed"
    exit 1
}
```

### CI/CD Integration

**GitHub Actions** example:

```yaml
name: Build ROM
on: [push, pull_request]
jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Download asar
        run: |
          Invoke-WebRequest -Uri "https://github.com/RPGHacker/asar/releases/download/v1.81/asar181.zip" -OutFile "asar.zip"
          Expand-Archive -Path "asar.zip" -DestinationPath "."
      - name: Build ROM
        run: .\build.ps1 -Clean
      - name: Verify Build
        run: .\tools\verify-build.ps1
      - name: Upload ROM
        uses: actions/upload-artifact@v3
        with:
          name: ffmq-rebuilt-rom
          path: build/ffmq-rebuilt.sfc
```

### Build Performance

**Typical Performance**:
- Cold build: 3-5 seconds
- Incremental: 1-2 seconds
- Clean build: 3-5 seconds

**Optimization Tips**:
- Use SSD for faster I/O
- Add build directory to antivirus exclusions
- Close resource-heavy applications
- Use PowerShell 7+ (faster than Windows PowerShell 5.1)

### Debugging Assembly Errors

**Enable Maximum Verbosity**:
```powershell
.\build.ps1 -Verbose
```

**Check Specific Bank**:
```powershell
# Build only one bank
asar src\asm\bank_00_documented.asm build\test.sfc
```

**Common Error Patterns**:

**"Label not found"**:
```asm
; Check for typos in label names
; Ensure label is defined before use
; Check label scope (local vs global)
```

**"File not found"**:
```asm
; Verify include paths
incsrc "path/to/file.asm"  ; Correct
incsrc "wrong/path.asm"    ; Error
```

**"Org too large"**:
```asm
; Data exceeds bank boundary
; Check .org directives
; Verify data size
```

## Getting Help

If you encounter issues:

1. **Check this guide** - Most common issues covered
2. **Review error messages** - Often contain the solution
3. **Check documentation** in `docs/` directory
4. **Search existing issues** on GitHub
5. **Ask on Discord/IRC** - Community support
6. **Open GitHub issue** - For bugs or unclear errors

## Quick Reference

```powershell
# Standard build
.\build.ps1

# Build with symbols
.\build.ps1 -Symbols

# Clean build with verbose output
.\build.ps1 -Clean -Verbose

# Custom output
.\build.ps1 -Output "custom.sfc"

# Verify build
.\tools\verify-build.ps1

# Test in emulator
mesen build\ffmq-rebuilt.sfc
```

## Next Steps

After building successfully:

1. **Test the ROM** in an emulator
2. **Review CONTRIBUTING.md** for making changes
3. **Explore the codebase** in `src/asm/`
4. **Join the community** and ask questions
5. **Start modding** or improving documentation

Happy building! 🎮✨
